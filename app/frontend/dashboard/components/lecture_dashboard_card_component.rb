# This component renders one lecture as a card on the student dashboard
# (main/start), showing the lecture image, title, lecturer, registration
# status and upcoming homework deadlines.
class LectureDashboardCardComponent < ViewComponent::Base
  REGISTRATION_STATUS_ICONS = {
    confirmed: "bi-check-circle-fill text-success",
    pending: "bi-hourglass-split text-warning",
    rejected: "bi-x-circle text-danger",
    open: "bi-person-plus text-primary"
  }.freeze

  # `activity` is the board's shared digest of unread forum topics and
  # comments. It is passed in so that it is gathered once for all cards; a card
  # rendered on its own falls back to gathering it for its own lecture.
  def initialize(lecture:, user:, activity: nil)
    super()
    @lecture = lecture
    @user = user
    @activity = activity
  end

  attr_reader :lecture, :user, :activity

  def image_url
    return "/no_course_information.png" unless lecture.course.normalized_image_file

    image_course_path(lecture.course, variant: "normalized")
  end

  def show_teacher?
    lecture.term || !lecture.disable_teacher_display
  end

  def card_style
    return @card_style if defined?(@card_style)

    @card_style = Dashboard::CardStyle.find_by(user: user, lecture: lecture)
  end

  def tape
    @tape ||= Dashboard::WashiTape.for(seed: lecture.id,
                                       color: card_style&.tape_color)
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
end
