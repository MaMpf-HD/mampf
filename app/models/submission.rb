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

  def correction_filename
    return unless correction.present?
    correction.metadata['filename']
  end

  def correction_size
    return unless correction.present?
    correction.metadata['size']
  end


  def preceding_tutorial(user)subm
    assignment.previous.submission(user)
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

  def filename_in_zip
		(users.map(&:tutorial_name).join('-') +
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
    archived_filestream = Zip::OutputStream.write_buffer do |stream|
      submissions.each do |s|
        stream.put_next_entry(s.filename_in_zip)
        stream.write IO.read(s.file_path)
      end
    end
    archived_filestream.rewind
    archived_filestream
  end

  def self.unzip_corrections!(tutorial, assignment, zipfile)
    submissions = Submission.where(tutorial: tutorial,
                                   assignment: assignment).proper
    report = { successful_extractions: 0, submissions: submissions.size,
    					 invalid_filenames: [], invalid_id: [], in_subfolder: [],
               no_decision: [], rejected: [], invalid_file: [] }
    tmp_folder = Dir.mktmpdir
    Zip::File.open(zipfile) do |zip_file|
      zip_file.each do |entry|
        if File.basename(entry.name) != entry.name
          report[:in_subfolder].push(entry.name)
          next
        end
      	if !'-ID-'.in?(entry.name)
      		report[:invalid_filenames].push(entry.name)
        	next
      	end
        submission = Submission.find_by_id(entry.name.split('-ID-').last
                                                .remove('.pdf'))
        if !submission
        	report[:invalid_id].push(entry.name)
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
        puts "Extracting #{entry.name}"
        extracted_file = File.join(tmp_folder, entry.name)
        entry.extract(extracted_file)
        submission.update(correction: File.open(extracted_file))
        if !submission.valid?
        	report[:invalid_file].push(entry.name)
        	next
        end
        report[:successful_extractions] += 1
      end
    end
    report
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
