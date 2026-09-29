# This component renders one lecture as a card on the student dashboard
# (main/start), showing the lecture image, title, lecturer, registration
# status and upcoming homework deadlines.
class LectureDashboardCardComponent < ViewComponent::Base
  # `activity` lets the board gather the unread digest once for all cards.
  # `section` is the board section the card sits in: a card in the
  # :bookmarked section gets a remove "x", and cards in the :staff and :tutor
  # sections leave out the student-only points progress and quick actions.
  # `term` is the semester the board shows; removing the card re-renders the
  # board for it. `talks` are the user's own talks in this seminar.
  # rubocop: disable Metrics/ParameterLists
  def initialize(lecture:, user:, term:, activity: nil, section: :enrolled, talks: [])
    super()
    @lecture = lecture
    @user = user
    @term = term
    @activity = activity
    @section = section
    @talks = talks
  end
  # rubocop: enable Metrics/ParameterLists

  attr_reader :lecture, :user, :term, :activity, :section, :talks

  def bookmarked?
    section == :bookmarked
  end

  def staff?
    section.in?([:staff, :tutor])
  end

  # Its tutors see a lecture here before it is published, but only its editors
  # may open it then.
  def href
    return if section == :tutor && !lecture.visible_for_user?(user)

    lecture_path(lecture)
  end

  def unpublished?
    staff? && !lecture.published?
  end

  def awaiting_group?
    section == :tutor && !user.given_tutorials.exists?(lecture: lecture) &&
      !user.given_cohorts.exists?(context: lecture)
  end

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
    @tape ||= Dashboard::WashiTape.new(seed: lecture.id,
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
  # Staff and tutors run the lecture rather than register for it.
  def show_registration_status?
    !staff? && registration_status.present? && registration_status != :confirmed
  end

  # Each date keeps together; with several, the line may wrap between them.
  def talk_dates(talk)
    dates = talk.dates.map { |date| tag.span(I18n.l(date, format: :concise), class: "text-nowrap") }
    safe_join(dates, ", ").presence
  end

  def talk_cospeakers(talk)
    cospeakers = helpers.cospeaker_list(talk, user)
    t("main.start.talk_with", names: cospeakers) if cospeakers.present?
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
