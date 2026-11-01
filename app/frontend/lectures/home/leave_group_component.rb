# The dialog in which a student leaves one of their groups. It names only
# what a student weighs before leaving: whether they still take part, what
# stays, and whether they can join again on their own. Leaving a last group
# that keeps nothing else is leaving the lecture and goes through
# LeaveLectureComponent instead.
class LeaveGroupComponent < ViewComponent::Base
  attr_reader :rosterable, :switch_targets

  # The participation row needs the label before this dialog renders, and a
  # component can translate only while it renders.
  def self.submit_key(rosterable)
    kind = { Tutorial => "tutorial", Talk => "talk" }.fetch(rosterable.class, "group")
    "registration.user_registration.participation.leave_#{kind}"
  end

  # switch_targets are the groups the student could switch to instead.
  def initialize(rosterable:, leave:, switch_targets: [])
    super()
    @rosterable = rosterable
    @leave = leave
    @switch_targets = switch_targets
  end

  def id
    "leave-#{rosterable.class.name.underscore}-#{rosterable.id}"
  end

  def title
    key = rosterable.is_a?(Talk) ? "leave_title_talk" : "leave_title"
    t("registration.user_registration.participation.#{key}",
      group: Rosters::LectureLeave.label(rosterable))
  end

  def submit_label
    t(self.class.submit_key(rosterable))
  end

  def url
    helpers.public_send("self_remove_#{rosterable.class.name.underscore}_path", rosterable.id)
  end

  def notes
    [participation_note, *kept_notes, points_note, rejoin_note].compact
  end

  private

    def last_place?
      @leave.only_place?(rosterable)
    end

    # Leaving the last group with enrollment ends taking part; without a
    # tutorial, no sheet can be handed in either.
    def participation_note
      suffix = rosterable.is_a?(Tutorial) ? "_tutorial" : ""
      if last_place?
        participation_t("leave_last_place#{suffix}")
      elsif @leave.enrolled?
        participation_t("leave_stays#{suffix}")
      end
    end

    # What leaving the lecture would take as well, and leaving this group does
    # not.
    def kept_notes
      return [] unless last_place?

      @leave.running_campaigns.map do |campaign|
        participation_t("leave_keeps_registration", title: campaign.student_facing_title)
      end + @leave.lists.map do |list|
        participation_t("leave_keeps_list", title: list.title)
      end
    end

    def points_note
      participation_t("leave_points_stay") if last_place? && rosterable.lecture.assignments.exists?
    end

    # A group that only lets students leave takes them back through its staff
    # alone.
    def rejoin_note
      key = if !rosterable.config_allow_self_add?
        "final"
      elsif rosterable.capacity
        "while_free"
      else
        "open"
      end
      participation_t("rejoin_#{key}")
    end

    def participation_t(key, **)
      t("registration.user_registration.participation.#{key}", **)
    end
end
