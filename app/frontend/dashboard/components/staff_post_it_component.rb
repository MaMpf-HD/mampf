# Gathers what the teaching staff need only now and then in one note at the
# end of their dashboard band, out of the way of their lectures' cards.
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
