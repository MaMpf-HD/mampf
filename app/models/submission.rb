class Submission < ApplicationRecord
  belongs_to :tutorial
  belongs_to :assignment

  has_many :user_submission_joins, dependent: :destroy
  has_many :users, through: :user_submission_joins

  self.implicit_order_column = "created_at"

  include SubmissionUploader[:manuscript]
  include CorrectionUploader[:correction]

  scope :proper, -> { where.not(manuscript_data: nil) }

  validate :matching_lecture, if: :tutorial

  before_create :set_token

  def partners_of_user(user)
    return unless user.in?(users)
    users - [user]
  end

  def team
  	users.map(&:tutorial_name).join(', ')
  end

  def manuscript_filename
    return unless manuscript.present?
    manuscript.metadata['filename']
  end

  def manuscript_size
    return unless manuscript.present?
    manuscript.metadata['size']
  end

  def manuscript_mime_type
return unless manuscript.present?
    manuscript.metadata['mime_type']
  end

  def correction_filename
    return unless correction.present?
    correction.metadata['filename']
  end

  def correction_size
    return unless correction.present?
    correction.metadata['size']
  end


  def preceding_tutorial(user)
    assignment.previous&.map { |a| a.tutorial(user) }&.compact&.first
  end

  def invited_users
  	User.where(id: invited_user_ids)
  end

  def self.generate_token
    loop do
      random_token = SecureRandom.base58(6)
      break random_token unless Submission.exists?(token: random_token)
    end
  end

  def admissible_invitees(user)
  	user.submission_partners(assignment.lecture) - users
  end

  def in_time?
    (last_modification_by_users_at || created_at) <= assignment.deadline
  end

  def too_late?
    !in_time?
  end

  def not_updatable?
    return false if assignment.active?
    assignment.totally_expired? || correction.present?
  end

  def file_path
  	return unless manuscript
  	manuscript.to_io.path
  end

  def filename_for_tutorial
		(users.map(&:tutorial_name).join('-') + '-' +
			I18n.l(last_modification_by_users_at, format: :short) +
			(too_late? ? '-LATE-' : '') +
			+ '-ID-' + id +
			'.pdf')
			.gsub(/[\x00\/\\:\*\?\"<>\|]/, '_')
	   	.gsub(/^.*(\\|\/)/, '')
   		# Strip out the non-ascii characters
   		.gsub(/[^0-9A-Za-z.\-]/, '_')
  end

  def self.zip_submissions!(tutorial, assignment)
		submissions = Submission.where(tutorial: tutorial,
                                   assignment: assignment).proper
    begin
      archived_filestream = Zip::OutputStream.write_buffer do |stream|
        submissions.each do |s|
          stream.put_next_entry(s.filename_for_tutorial)
          stream.write IO.read(s.file_path)
        end
      end
      archived_filestream.rewind
    rescue => e
      archived_filestream = e.message
    end
    archived_filestream
  end

  def check_file_properties(metadata)
    errors = []
    if metadata['size'] > 10*1024*1024
      errors.push I18n.t('submission.manuscript_size_too_big',
                         max_size: '10 MB')
    end
    file_name = metadata['filename']
    file_type = File.extname(file_name)
    if file_type != assignment.accepted_file_type &&
      assignment.accepted_file_type != '.tar.gz'
      errors.push I18n.t('submission.wrong_file_type',
                         file_type: file_type,
                         accepted_file_type: assignment.accepted_file_type)
    end
    if file_type == '.gz' && assignment.accepted_file_type == '.tar.gz' &&
      File.extname(File.basename(file_name)) != '.tar'
      errors.push I18n.t('submission.wrong_file_type',
                         file_type: File.extname(File.basename(file_name)),
                         accepted_file_type: '.tar.gz')
    end
    if (!assignment.accepted_file_type.in?(['.cc', '.hh']) &&
      !metadata['mime_type'].in?(assignment.accepted_mime_types)) ||
      (assignment.accepted_file_type.in?(['.cc', '.hh']) &&
        !metadata['mime_type'].starts_with?('text/'))
      errors.push I18n.t('submission.wrong_mime_type',
                          mime_type: metadata['mime_type'],
                          accepted_mime_types: assignment.accepted_mime_types
                                                         .join(', '))
    end
    return {} unless errors.present?
    { manuscript: errors }
  end

  private

	def matching_lecture
		return true if tutorial&.lecture == assignment.lecture
		errors.add(:tutorial, :lecture_not_matching)
	end

  def set_token
    self.token = Submission.generate_token
  end
end
