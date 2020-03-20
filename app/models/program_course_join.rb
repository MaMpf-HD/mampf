class ProgramCourseJoin < ApplicationRecord
  belongs_to :program
  belongs_to :course
end
