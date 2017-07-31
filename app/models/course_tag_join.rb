# CourseTagJoin class
# JoinTable for course <-> tag many-to-many-relation
class CourseTagJoin < ApplicationRecord
  belongs_to :course
  belongs_to :tag
end
