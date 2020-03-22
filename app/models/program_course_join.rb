class ProgramCourseJoin < ApplicationRecord
  belongs_to :program
  belongs_to :course

  enum level: { basic: 0, advanced: 1, expert: 3 }
end
