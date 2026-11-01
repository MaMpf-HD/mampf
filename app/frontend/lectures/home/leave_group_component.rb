# The dialog in which a student leaves one of their groups. It says whether
# they stay enrolled, what stays when the group was their last one with
# enrollment, and whether they can join it again on their own.
class LeaveGroupComponent < ViewComponent::Base
  include UserRegistrationsHelper

  attr_reader :rosterable

  # The participation row needs the label before this dialog renders, and a
  # component can translate only while it renders.
  def self.submit_key(rosterable)
    kind = { Tutorial => "tutorial", Talk => "talk" }.fetch(rosterable.class, "group")
    "registration.user_registration.participation.leave_#{kind}"
  end

  def initialize(rosterable:, user:, leave:)
    super()
    @rosterable = rosterable
    @user = user
    @leave = leave
  end

  def id
    "leave-#{rosterable.class.name.underscore}-#{rosterable.id}"
  end

  def label
    Rosters::LectureLeave.label(rosterable)
  end

  def title
    key = rosterable.is_a?(Talk) ? "leave_title_talk" : "leave_title"
    t("registration.user_registration.participation.#{key}", group: label)
  end

  def submit_label
    t(self.class.submit_key(rosterable))
  end

  def url
    helpers.public_send("self_remove_#{rosterable.class.name.underscore}_path", rosterable.id)
  end

  def last_place?
    @leave.only_place?(rosterable)
  end

  def stays_enrolled?
    !last_place? && @leave.enrolled?
  end

  # What stays when the last group with enrollment goes: the flexible groups
  # without enrollment and the running registrations.
  def remaining
    lists = Cohort.lists_by_user(lecture, [@user.id]).fetch(@user.id, []).map(&:title)
    lists + campaigns.map do |campaign|
      t("roster.left.registered_for", title: campaign.student_facing_title)
    end
  end

  def bookmarked?
    @user.lectures.include?(lecture)
  end

  # The dashboard offers to forget a bookmarked lecture only while no
  # registration keeps it among the student's own lectures.
  def bookmark_note
    key = campaigns.empty? ? "leave_bookmark_stays" : "leave_bookmark_stays_short"
    t("registration.user_registration.participation.#{key}")
  end

  def rejoin_note
    t("registration.user_registration.participation.rejoin_#{rejoin_key}")
  end

  private

    def lecture
      rosterable.lecture
    end

    def campaigns
      @campaigns ||= Registration::UserRegistration.running_campaigns_by_user(lecture, [@user.id])
                                                   .fetch(@user.id, [])
    end

    # A group that only lets students leave takes them back through its staff
    # alone.
    def rejoin_key
      if !rosterable.config_allow_self_add?
        "final"
      elsif rosterable.capacity
        "while_free"
      else
        "open"
      end
    end
end
