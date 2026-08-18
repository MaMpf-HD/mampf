# This component renders one seminar talk given by the current user as a
# big card on the student dashboard (main/start), in the same visual shell
# as LectureDashboardCardComponent.
class TalkDashboardCardComponent < ViewComponent::Base
  def initialize(talk:, user:)
    super()
    @talk = talk
    @user = user
  end

  attr_reader :talk, :user

  def image_url
    return "/no_course_information.png" unless talk.lecture.course.normalized_image_file

    image_course_path(talk.lecture.course, variant: "normalized")
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
