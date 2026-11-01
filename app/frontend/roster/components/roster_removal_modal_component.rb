# The dialog in which the staff confirm taking someone off a roster. It names
# what the person loses and what stays, lets the staff keep the flexible groups
# without enrollment when the person leaves the whole lecture, and asks
# whether to tell them.
class RosterRemovalModalComponent < ViewComponent::Base
  attr_reader :rosterable, :url

  def initialize(user:, rosterable:, url:)
    super()
    @user = user
    @rosterable = rosterable
    @url = url
  end

  def from_lecture?
    rosterable.is_a?(Lecture)
  end

  def exam?
    rosterable.is_a?(Exam)
  end

  def title
    if from_lecture?
      t("roster.removal_modal.title_lecture", user: name)
    elsif exam?
      t("roster.removal_modal.title_exam", user: name, group: rosterable.title)
    else
      t("roster.removal_modal.title_group", user: name,
                                            group: Rosters::LectureLeave.label(rosterable))
    end
  end

  # The groups with enrollment and the exam lists the person leaves with the
  # lecture.
  def places
    leave.places.map { |group| Rosters::LectureLeave.label(group) }
  end

  def lists
    @lists ||= Cohort.lists_by_user(lecture, [@user.id]).fetch(@user.id, [])
  end

  def campaigns
    @campaigns ||= Registration::UserRegistration.running_campaigns_by_user(lecture, [@user.id])
                                                 .fetch(@user.id, [])
  end

  def last_place?
    !from_lecture? && leave.only_place?(rosterable)
  end

  def stays_enrolled?
    !from_lecture? && !last_place? && rosterable.enrolls_in_lecture? && leave.enrolled?
  end

  private

    def name
      @user.tutorial_name.presence || @user.email
    end

    def lecture
      from_lecture? ? rosterable : rosterable.lecture
    end

    def leave
      @leave ||= Rosters::LectureLeave.new(lecture, @user)
    end
end
