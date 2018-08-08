class CourseUserJoin < ApplicationRecord
  belongs_to :course
  belongs_to :user

  def kaviar?
    return unless course.kaviar?
    user.lectures.where(id: course.lectures).present?
  end
end
