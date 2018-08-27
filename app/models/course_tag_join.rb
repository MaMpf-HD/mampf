# CourseTagJoin class
# JoinTable for course <-> tag many-to-many-relation
class CourseTagJoin < ApplicationRecord
  belongs_to :course
  belongs_to :tag
  after_save :touch_tag
  before_destroy :touch_tag

  private

  def touch_tag
    return unless tag.present?
    tag.touch
  end
end
