# Term class
class Term < ApplicationRecord
  has_many :lectures
  validates :season, presence: true,
                     inclusion: { in: %w[SS WS],
                                  message: 'not a valid type' },
                     uniqueness: { scope: :year,
                                   message: 'Semester existiert bereits.' }
  validates :year, presence: true,
                   numericality: { only_integer: true,
                                   greater_than_or_equal_to: 2000 }
  paginates_per 8

  def begin_date
    season == 'SS' ? Date.new(year, 4, 1) : Date.new(year, 10, 1)
  end

  def end_date
    season == 'SS' ? Date.new(year, 9, 30) : Date.new(year + 1, 3, 31)
  end

  def to_label
    return unless season.present?
    season + ' ' + year_corrected
  end

  def to_label_short
    season + ' ' + year_corrected_short
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
end
