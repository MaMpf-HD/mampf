# The staff's dialog for taking someone off a roster: it names what goes and
# what stays, and asks whether to tell the person.
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

  def places
    leave.places.map { |group| Rosters::LectureLeave.label(group) }
  end

  delegate :lists, to: :leave

  # Removal from the lecture withdraws rejected registrations too, since an
  # allocation can still give them a place; removal from the last group keeps
  # every registration.
  def campaigns
    @campaigns ||= if from_lecture?
      Rosters::UserPlaces.new(@user).campaigns_to_withdraw([lecture]).to_a
    else
      leave.running_campaigns.to_a
    end
  end

  # A result keeps the person on the roster; the dialog then says so instead
  # of offering a removal that would be refused.
  def graded?
    return @graded if defined?(@graded)

    @graded = Rosters::MaintenanceService.new.grading_data?(@user, rosterable)
  end

  def graded_note
    key = from_lecture? ? "lecture_grading_data_present" : "grading_data_present"
    t("roster.errors.#{key}")
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
