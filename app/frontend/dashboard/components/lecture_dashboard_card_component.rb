# This component renders one lecture as a big card on the student dashboard
# (main/start), showing the lecture image, title, lecturer, registration
# status and upcoming homework deadlines.
class LectureDashboardCardComponent < ViewComponent::Base
  DUE_SOON_WINDOW = 7.days

  REGISTRATION_STATUS_ICONS = {
    confirmed: "bi-check-circle-fill text-success",
    pending: "bi-hourglass-split text-warning",
    rejected: "bi-x-circle text-danger",
    open: "bi-person-plus text-primary"
  }.freeze

  def initialize(lecture:, user:)
    super()
    @lecture = lecture
    @user = user
  end

  attr_reader :lecture, :user

  def image_url
    return "/no_course_information.png" unless lecture.course.normalized_image_file

    image_course_path(lecture.course, variant: "normalized")
  end

  def show_teacher?
    lecture.term || !lecture.disable_teacher_display
  end

  def favorite?
    lecture.in?(user.favorite_lectures)
  end

  def registration_status
    @registration_status ||= lecture.registration_status_for(user)
  end

  def registration_status_label
    return t("main.start.registration_open") if registration_status == :open

    t("registration.user_registration.status.#{registration_status}")
  end

  def registration_status_icon
    REGISTRATION_STATUS_ICONS[registration_status]
  end

  def next_assignment_deadline
    @next_assignment_deadline ||= lecture.next_pending_assignment_deadline_for(user)
  end

  def homework_due_soon?
    next_assignment_deadline.present? &&
      next_assignment_deadline <= DUE_SOON_WINDOW.from_now
  end
end
