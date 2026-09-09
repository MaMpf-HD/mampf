# This component renders one seminar talk given by the current user as a
# card on the student dashboard (main/start), in the same visual shell as
# LectureDashboardCardComponent.
class TalkDashboardCardComponent < ViewComponent::Base
  def initialize(talk:, user:)
    super()
    @talk = talk
    @user = user
  end

  attr_reader :talk, :user

  delegate :lecture, to: :talk

  def image_url
    return "/no_course_information.png" unless lecture.course.normalized_image_file

    image_course_path(lecture.course, variant: "normalized")
  end

  def card_style
    return @card_style if defined?(@card_style)

    @card_style = Dashboard::CardStyle.find_by(user: user, lecture: lecture)
  end

  # Keyed to the seminar, not the single talk: a student presenting in a
  # seminar they are also enrolled in should see one colour for it, and
  # changing it on either card should move the other.
  def tape
    @tape ||= Dashboard::WashiTape.for(seed: lecture.id,
                                       color: card_style&.tape_color)
  end

  def dates_text
    talk.dates.map { |d| I18n.l(d, format: :concise) }.join(", ")
  end

  def cospeaker?
    talk.speakers.size > 1
  end

  def cospeaker_text
    helpers.cospeaker_list(talk, user)
  end
end
