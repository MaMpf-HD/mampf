# This component renders one lecture as a card on the student dashboard
# (main/start), showing the lecture image, title, lecturer, registration
# status and upcoming homework deadlines.
class LectureDashboardCardComponent < ViewComponent::Base
  # `activity` lets the board gather the unread digest once for all cards.
  # `bookmarked` marks a card in the "Bookmarked" band, which gets a remove "x".
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

    @card_style = if activity
      activity.card_style(lecture)
    else
      Dashboard::CardStyle.find_by(user: user, lecture: lecture)
    end
  end

  def tape
    @tape ||= Dashboard::WashiTape.for(seed: lecture.id,
                                       color: card_style&.tape_color)
  end

  # `defined?` rather than `||=`, as nil (no registration) is a common answer.
  def registration_status
    return @registration_status if defined?(@registration_status)

    @registration_status = if activity
      activity.registration_status(lecture)
    else
      lecture.registration_status_for(user)
    end
  end

  # Confirmed is the default state of this band, so only show flux states.
  def show_registration_status?
    registration_status.present? && registration_status != :confirmed
  end

  def registration_status_label
    helpers.registration_status_label(registration_status)
  end

  def registration_status_icon
    helpers.registration_status_icon(registration_status)
  end

  # Removing the bookmark locks a lecture behind a pass phrase again. A student
  # on its roster can unlock it without the pass phrase, so only the others are
  # warned.
  def relocked_by_removal?
    lecture.restricted? && !LectureMembership.exists?(user: user, lecture: lecture)
  end

  def remove_bookmark_body
    key = relocked_by_removal? ? "remove_bookmark_body_locked" : "remove_bookmark_body"
    t("main.start.#{key}", lecture: lecture.title_no_term)
  end

  def remove_registration_notice_body
    body = t("main.start.remove_registration_notice_body", lecture: lecture.title_no_term)
    return body unless relocked_by_removal? && lecture.bookmarked_by?(user)

    "#{body} #{t("main.start.remove_entirely_relocks")}"
  end
end
