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
  	users.map(&:tutorial_name).natural_sort.join(', ')
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

  def correction_mime_type
		return unless correction.present?
    correction.metadata['mime_type']
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

  def filename_for_bulk_download
		(team.first(180) + '-' +
			last_modification_by_users_at.strftime("%F-%H%M") +
			(too_late? ? '-LATE' : '') +
			+ '-ID-' + id +
			assignment.accepted_file_type)
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
          stream.put_next_entry(s.filename_for_bulk_download)
          stream.write IO.read(s.file_path)
        end
      end
      archived_filestream.rewind
    rescue => e
      archived_filestream = e.message
    end
    archived_filestream
  end

  def check_file_properties(metadata, sort)
    errors = []
    if sort == :submission && metadata['size'] > 10*1024*1024
      errors.push I18n.t('submission.manuscript_size_too_big',
                         max_size: '10 MB')
    end
    if sort == :correction && metadata['size'] > 15*1024*1024
      errors.push I18n.t('submission.manuscript_size_too_big',
                         max_size: '15 MB')
    end
    file_name = metadata['filename']
    file_type = File.extname(file_name)
    if file_type != assignment.accepted_file_type &&
      assignment.accepted_file_type != '.tar.gz'
      errors.push I18n.t('submission.wrong_file_type',
                         file_type: file_type,
                         accepted_file_type: assignment.accepted_file_type)
    end
    if assignment.accepted_file_type == '.tar.gz'
    	if file_type == '.gz'
    		reduced_type = File.extname(File.basename(file_name, '.gz'))
    		if reduced_type != '.tar'
					errors.push I18n.t('submission.wrong_file_type',
                      			 file_type: '.gz',
                      			 accepted_file_type: '.tar.gz')
        end
      else
				errors.push I18n.t('submission.wrong_file_type',
                      		 file_type: file_type,
                     	 		 accepted_file_type: '.tar.gz')
			end
    end
    if (!assignment.accepted_file_type.in?(['.cc', '.hh', '.m']) &&
      !metadata['mime_type'].in?(assignment.accepted_mime_types)) ||
      (assignment.accepted_file_type.in?(['.cc', '.hh', '.m']) &&
        (!metadata['mime_type'].starts_with?('text/') &&
         metadata['mime_type'] != 'application/octet-stream'))
      errors.push I18n.t('submission.wrong_mime_type',
                          mime_type: metadata['mime_type'],
                          accepted_mime_types: assignment.accepted_mime_types
                                                         .join(', '))
    end
    return {} unless errors.present?
    { sort => errors }
  end

  def self.bulk_corrections!(tutorial, assignment, files)
    submissions = Submission.where(tutorial: tutorial,
                                   assignment: assignment).proper
    report = { successful_extractions: 0, submissions: submissions.size,
    					 invalid_filenames: [], invalid_id: [], in_subfolder: [],
               no_decision: [], rejected: [], invalid_file: [] }
    tmp_folder = Dir.mktmpdir
    begin
      files.each do |file_shrine|
      #Zip::File.open(zipfile) do |zip_file|
      #  zip_file.each do |entry|
        p "EEE2",file_shrine
          filename = file_shrine["metadata"]["filename"]
      	  if !'-ID-'.in?(filename)
      	 	  report[:invalid_filenames].push(filename)
        	  next
      	  end
          submission = Submission.find_by_id(filename.split('-ID-').last
                                                  .remove('.pdf'))
          if !submission
        	  report[:invalid_id].push(filename)
        	  next
          end
          if submission.too_late? && submission.accepted.nil?
        	  report[:no_decision].push(submission.team)
        	  next
          end
          if submission.too_late? && submission.accepted == false
					  report[:rejected].push(submission.team)
        	  next
          end
          submission.update(correction: file_shrine.to_json)
          if !submission.valid?
        	  report[:invalid_file].push(filename)
        	  next
          end
          report[:successful_extractions] += 1
       # end
      end
    rescue => e
      report[:errors] = "#{e.message}"
    end
    report
  end

  private

	def matching_lecture
		return true if tutorial&.lecture == assignment&.lecture
		errors.add(:tutorial, :lecture_not_matching)
	end

  def set_token
    self.token = Submission.generate_token
  end
end
