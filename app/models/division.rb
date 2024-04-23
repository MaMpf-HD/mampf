class Division < ApplicationRecord
  belongs_to :program
  has_many :division_course_joins
  has_many :courses, through: :division_course_joins
  extend Mobility
  translates :name

  def name_with_program
    "#{program.subject.name}:#{program.name}:#{name}"
  end
end
