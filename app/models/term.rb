# Term class
class Term < ApplicationRecord
  # in a term, many lectures take place
  has_many :lectures

  # season can only be SS/WS, and there can be only one of this type each year
  validates :season, presence: true,
                     inclusion: { in: %w[SS WS] },
                     uniqueness: { scope: :year }
  # a year >=2000 needs to be present
  validates :year, presence: true,
                   numericality: { only_integer: true,
                                   greater_than_or_equal_to: 2000 }

  # only one term can be active
  validates_uniqueness_of :active, if: :active

  # some information about lectures, lessons and media are cached
  # to find out whether the cache is out of date, always touch'em after saving
  after_save :touch_lectures_and_lessons
  after_save :touch_media

  paginates_per 8

  def self.active
    Term.find_by(active: true)
  end

  def active
    self == Term.active
  end

  def begin_date
    season == 'SS' ? Date.new(year, 4, 1) : Date.new(year, 10, 1)
  end

  def end_date
    season == 'SS' ? Date.new(year, 9, 30) : Date.new(year + 1, 3, 31)
  end

  # label contains season and year(s) with all digits
  def to_label
    return unless season.present?
    season + ' ' + year_corrected
  end

  # short label contains season and year(s) with two digits
  def to_label_short
    season + ' ' + year_corrected_short
  end

  def compact_title
    season + year_corrected_short
  end

  def previous
    previous_year = season == 'WS' ? year : year - 1
    previous_season = season == 'WS' ? 'SS' : 'WS'
    Term.find_by(year: previous_year, season: previous_season)
  end

  def assignments
    Assignment.where(lecture: lectures)
  end

  def submissions
    Submission.where(assignment: assignments)
  end

  def submitter_ids
    UserSubmissionJoin.where(submission: submissions).pluck(:user_id).uniq
  end

  def submitters
    User.where(id: submitter_ids)
  end

  def assignments_with_submissions
    Assignment.where(id: submissions.pluck(:assignment_id).uniq)
  end

  def lectures_with_submissions
    Lecture.where(id: assignments_with_submissions.pluck(:lecture_id).uniq)
  end

  def people_in_charge_of_submissions
    (lectures_with_submissions.map(&:editors).flatten +
      lectures_with_submissions.map(&:teacher)).uniq
  end

  def submission_deletion_info_dates
    [end_date + 1.day, end_date + 8.days, submission_deletion_date]
  end

  def self.possible_deletion_dates
    return [Time.zone.today + 6.months] if Term.active.blank?

    [Term.active.end_date + 2.weeks + 1.day,
     Term.active.end_date + 2.weeks + 3.months + 1.day,
     Term.active.end_date + 2.weeks + 6.months + 1.day]
  end

  def self.possible_deletion_dates_localized
    possible_deletion_dates.map { |d| d.strftime(I18n.t('date.formats.concise')) }
  end

  # array of all terms together with their ids for use in options_for_select
  def self.select_terms(independent = false)
    return ['bla', nil] if independent
    Term.all.sort_by(&:begin_date).reverse.map { |t| [t.to_label, t.id] }
  end

  def self.previous_by_date(date)
    season = date.month.in?((4..9)) ? 'SS' : 'WS'
    year = date.year
    previous_year = season == 'WS' ? year : year - 1
    previous_season = season == 'WS' ? 'SS' : 'WS'
    Term.find_by(year: previous_year, season: previous_season)
  end

  private

  def year_corrected
    return year.to_s unless season == 'WS'
    year.to_s + '/' + ((year % 100) + 1).to_s
  end

  def year_corrected_short
    return (year % 100).to_s unless season == 'WS'
    (year % 100).to_s + '/' + ((year % 100) + 1).to_s
  end

  def touch_lectures_and_lessons
    lectures.update_all(updated_at: Time.now)
    Lesson.where(lecture: lectures).update_all(updated_at: Time.now)
  end

  def touch_media
    Medium.where(teachable: lectures).update_all(updated_at: Time.now)
    Medium.where(teachable: Lesson.where(lecture: lectures))
          .update_all(updated_at: Time.now)
  end
end
