# Term class
class Term < ApplicationRecord
  # in a term, many lectures take place
  has_many :lectures

  # season can only be SS/WS, and there can be only one of this type each year
  validates :season, presence: true,
                     inclusion: { in: %w[SS WS],
                                  message: 'not a valid type' },
                     uniqueness: { scope: :year,
                                   message: 'Semester existiert bereits.' }
  # a year >=2000 needs to be present
  validates :year, presence: true,
                   numericality: { only_integer: true,
                                   greater_than_or_equal_to: 2000 }

  # some information about lectures, lessons and media are cached
  # to find out whether the cache is out of date, always touch'em after saving
  after_save :touch_lectures_and_lessons
  after_save :touch_media

  paginates_per 8

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

  # array of all terms togther with their ids for use in options_for_select
  def self.select_terms
    Term.all.map { |t| [t.to_label, t.id] }
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
