# Pins what the teaching staff need now and then, but no longer find in an
# administration area of their own, to the end of their dashboard band:
# creating a lecture, the courses they edit, and the search for media and
# tags.
class StaffPostItComponent < ViewComponent::Base
  COURSES_MODAL_ID = "staff-courses-modal".freeze

  def initialize(user:)
    super()
    @user = user
  end

  def render?
    !@user.generic?
  end

  def create_lecture?
    @user.course_editor? || @user.admin?
  end

  def courses
    @courses ||= @user.edited_courses.natural_sort_by(&:title)
  end
end
