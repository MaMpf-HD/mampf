# The dialog in which a student leaves one of their groups, naming only what
# they weigh before leaving. A last group that keeps nothing else is left
# through LeaveLectureComponent.
class LeaveGroupComponent < ViewComponent::Base
  attr_reader :rosterable, :switch_targets

  # The participation row needs the label before this dialog renders, and a
  # component can translate only while it renders.
  def self.submit_key(rosterable)
    kind = { Tutorial => "tutorial", Talk => "talk" }.fetch(rosterable.class, "group")
    "registration.user_registration.participation.leave_#{kind}"
  end

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
    @notes ||= [participation_note, *kept_notes, points_note, rejoin_note].compact
  end

  # A result or an exam registration past its deadline keeps the student in
  # their last group; the dialog then says why instead of offering to leave.
  def held?
    last_place? && blockers.any?
  end

  def blocker_notes
    blockers.map do |blocker|
      t("lecture_home.leave.blockers.#{blocker.reason}", title: blocker.title)
    end
  end

  def contact?
    blockers.any?(&:staff_can_help)
  end

  private

    def last_place?
      @leave.only_place?(rosterable)
    end

    def tutorial?
      rosterable.is_a?(Tutorial)
    end

    # Without a tutorial, no sheet can be handed in; leaving another group
    # keeps an enrolled student in the lecture.
    def participation_note
      if last_place?
        participation_t("leave_no_sheets") if tutorial?
      elsif @leave.enrolled?
        participation_t(tutorial? ? "leave_stays_tutorial" : "leave_stays")
      end
    end

    # What leaving the lecture would take as well, and leaving this group does
    # not. The first of these also says that the lecture stays on the
    # dashboard.
    def kept_notes
      return [] unless last_place?

      kept = @leave.running_campaigns.map { |c| ["registration", c.student_facing_title] } +
             @leave.lists.map { |list| ["list", list.title] }
      kept.each_with_index.map do |(kind, title), index|
        suffix = index.zero? && on_dashboard? ? "_dashboard" : ""
        participation_t("leave_keeps_#{kind}#{suffix}", title: title)
      end
    end

    # A running registration keeps the lecture among the student's own on the
    # dashboard, a bookmark among the bookmarked ones.
    def on_dashboard?
      @leave.running_campaigns.any? || @leave.bookmarked?
    end

    def points_note
      participation_t("leave_points_stay") if last_place? && rosterable.lecture.assignments.exists?
    end

    def rejoin_note
      participation_t("rejoin_final") unless rosterable.config_allow_self_add?
    end

    def blockers
      @leave.last_place_blockers
    end

    def participation_t(key, **)
      t("registration.user_registration.participation.#{key}", **)
    end
end
