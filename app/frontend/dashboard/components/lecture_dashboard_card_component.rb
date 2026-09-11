# This component renders one lecture as a card on the student dashboard
# (main/start), showing the lecture image, title, lecturer, registration
# status and upcoming homework deadlines.
class LectureDashboardCardComponent < ViewComponent::Base
  # `activity` is the board's shared digest of unread forum topics and
  # comments. It is passed in so that it is gathered once for all cards; a card
  # rendered on its own falls back to gathering it for its own lecture.
  #
  # `bookmarked` marks a card that sits in the "Bookmarked" band rather than
  # among the enrolled lectures: it gets the small "x" that removes the
  # bookmark.
  def initialize(lecture:, user:, activity: nil, bookmarked: false)
    super()
    @lecture = lecture
    @user = user
    @activity = activity
    @bookmarked = bookmarked
  end

  attr_reader :lecture, :user, :activity, :bookmarked
  alias bookmarked? bookmarked

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
    Registration::StatusPresenter.label(registration_status)
  end

  def registration_status_icon
    Registration::StatusPresenter.icon(registration_status)
  end
end
