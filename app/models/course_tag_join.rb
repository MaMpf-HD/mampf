# CourseTagJoin class
# JoinTable for course <-> tag many-to-many-relation
class CourseTagJoin < ApplicationRecord
  belongs_to :course
  belongs_to :tag

  # tags are cached in several situations
  # in order to see when changes have been made,
  # touches are triggered
  after_save :touch_tag
  before_destroy :touch_tag

  private

    def touch_tag
      return unless tag.present? && tag.persisted?

      tag.touch
    end
end
