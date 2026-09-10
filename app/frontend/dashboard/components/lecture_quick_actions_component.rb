# The little speech bubbles pinned beside a lecture's dashboard card: the one
# or two things the student could act on in that lecture right now, each one a
# single link to the page where they would do it.
#
# Only what is actionable belongs here. Anything that is merely the lecture's
# state (the registration status, the points so far) stays on the card itself,
# so a bubble always means "there is something for you to do".
class LectureQuickActionsComponent < ViewComponent::Base
  DUE_SOON_WINDOW = 7.days

  # Degrees a bubble is tilted against the rail. Far smaller than the cards'
  # tilt: a bubble is a few words wide, and past a degree or two the text
  # starts to look broken rather than hand-placed.
  MAX_TILT = 1.5

  Action = Struct.new(:kind, :icon, :label, :cta, :href, keyword_init: true)

  def initialize(lecture:, user:, activity: nil)
    super()
    @lecture = lecture
    @user = user
    @activity = activity
  end

  attr_reader :lecture, :user

  def render?
    actions.any?
  end

  def actions
    @actions ||= [assignment_action, exam_registration_action, activity_action]
                 .compact
  end

  def list_label
    t("dashboard.quick_actions.list_label", lecture: lecture.title_no_term)
  end

  # Alternating directions in half-degree steps, seeded by the lecture, so a
  # rail of bubbles reads as stuck on one by one rather than printed.
  def tilt(index)
    magnitude = ((lecture.id + (index * 7)) % ((2 * MAX_TILT) + 1)) / 2.0
    magnitude * (index.even? ? 1 : -1)
  end

  def style(index)
    "--quick-action-tilt: #{tilt(index)}deg"
  end

  private

    def activity
      @activity ||= Dashboard::LectureActivity.new(user: user,
                                                   lectures: [lecture])
    end

    def next_assignment_deadline
      return @next_assignment_deadline if defined?(@next_assignment_deadline)

      @next_assignment_deadline = lecture.next_pending_assignment_deadline_for(user)
    end

    def assignment_action
      return unless next_assignment_deadline
      return unless next_assignment_deadline <= DUE_SOON_WINDOW.from_now

      Action.new(
        kind: "assignment",
        icon: "bi-alarm",
        label: t("dashboard.quick_actions.assignment.label",
                 date: I18n.l(next_assignment_deadline, format: :long)),
        cta: t("dashboard.quick_actions.assignment.cta"),
        href: lecture_submissions_path(lecture)
      )
    end

    def exam_registration_action
      return unless lecture.open_exam_registration_for(user)

      Action.new(
        kind: "exam",
        icon: "bi-pencil-square",
        label: t("dashboard.quick_actions.exam.label"),
        cta: t("dashboard.quick_actions.exam.cta"),
        href: lecture_path(lecture)
      )
    end

    # The forum and the comments under the media are one bubble, not two: they
    # are the same errand ("people have written things"), and they lead to the
    # same page.
    def activity_action
      parts = activity_parts
      return if parts.empty?

      Action.new(
        kind: "activity",
        icon: "bi-chat-left-text",
        label: parts.to_sentence,
        cta: t("dashboard.quick_actions.activity.cta"),
        href: lecture_path(lecture)
      )
    end

    def activity_parts
      counts = { forum: activity.unread_forum_topics(lecture),
                 comments: activity.unread_comments(lecture) }

      counts.filter_map do |kind, count|
        next unless count.positive?

        t("dashboard.quick_actions.activity.#{kind}", count: count)
      end
    end
end
