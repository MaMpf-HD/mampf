# CourseUserJoin class
# JoinTable for course <-> user many-to-many-relation
# that describes which sers whave subscribed to which courses
class CourseUserJoin < ApplicationRecord
  belongs_to :course
  belongs_to :user
end
