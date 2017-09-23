# Term class
class Term < ApplicationRecord
  has_many :lectures
  validates :season, presence: true,
                     inclusion: { in: %w[SS WS],
                                  message: 'not a valid type' },
                     uniqueness: { scope: :year,
                                   message: 'term already exists' }
  validates :year, presence: true,
                   numericality: { only_integer: true,
                                   greater_than_or_equal_to: 2000,
                                   less_than_or_equal_to: 2200 }

  def begin_date
    season == 'SS' ? Date.new(year, 4, 1) : Date.new(year, 10, 1)
  end

  def end_date
    season == 'SS' ? Date.new(year, 9, 30) : Date.new(year + 1, 3, 31)
  end

  def to_label
    season + ' ' + year.to_s
  end
end
