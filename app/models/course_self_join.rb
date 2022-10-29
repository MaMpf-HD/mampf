# CourseSelfJoin class
# JoinTable for course<->course many-to-many-relation
# that describes on which courses a given course
# is built upon
class CourseSelfJoin < ApplicationRecord
  belongs_to :course
  belongs_to :preceding_course, class_name: 'Course'
  validates :preceding_course, uniqueness: { scope: :course}

  # we do not allow a course to be preceding itself
  after_save :destroy, if: :self_inverse?

  private

  def self_inverse?
    course_id == preceding_course_id
  end
end
