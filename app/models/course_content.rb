# CourseContent class
# JoinTable for course <-> tag many-to-many-relation
class CourseContent < ApplicationRecord
  belongs_to :course
  belongs_to :tag
end
