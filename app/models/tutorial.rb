# Tutorial model
class Tutorial < ApplicationRecord
  require 'csv'

  belongs_to :lecture, touch: true

  has_many :tutor_tutorial_joins, dependent: :destroy
  has_many :tutors, through: :tutor_tutorial_joins

  has_many :submissions, dependent: :destroy

  before_destroy :check_destructibility, prepend: true

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true

  def title_with_tutors
  	return "#{title}, #{I18n.t('basics.tba')}" unless tutors.any?
  	"#{title}, #{tutor_names}"
  end

  def tutor_names
  	return unless tutors.any?
  	tutors.map(&:tutorial_name).join(', ')
  end

  def destructible?
		Submission.where(tutorial: self).proper.none?
  end

  def add_bulk_corrections!(assignment, files)
    relevant_submissions = submissions.where(assignment: assignment).proper
    report = { successful_saves: [], submissions: relevant_submissions.size,
               invalid_filenames: [], invalid_id: [],
               no_decision: [], rejected: [], invalid_file: [] }
    files.each do |file_shrine|
      filename = file_shrine["metadata"]["filename"]
      if !'-ID-'.in?(filename)
        report[:invalid_filenames].push(filename)
        next
      end
      submission = Submission.find_by_id(filename.split('-ID-').last
                                              	 .split('.')&.first)
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
      submission.correction = file_shrine.to_json
			errors = submission.check_file_properties(submission.correction
                                                           .metadata,
                                                :correction)
			if errors.present?
        report[:invalid_file].push(filename)
        next
			end
      submission.update(correction: file_shrine.to_json)
      if !submission.valid?
        report[:invalid_file].push(filename)
        next
      end
      report[:successful_saves].push(submission)
    end
    report
  end

  def teams_to_csv(assignment)
    submissions = Submission.where(tutorial: self, assignment: assignment)
                            .proper.order(:last_modification_by_users_at)
    CSV.generate(headers: false) do |csv|
      submissions.each do |s|
        csv << [s.team]
      end
    end
  end

  private

  def check_destructibility
  	throw(:abort) unless destructible?
  	true
  end
end
