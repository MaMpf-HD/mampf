# Speech bubbles beside a lecture's card, one per actionable item (deadlines,
# open exam registration, unread activity). Purely informational state stays
# on the card itself.
class LectureQuickActionsComponent < ViewComponent::Base
  DUE_SOON_WINDOW = 7.days
  MAX_TILT = 1.5

  Action = Struct.new(:kind, :icon, :label, :href, keyword_init: true)

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
        href: lecture_submissions_path(lecture)
      )
    end

    def exam_registration_action
      return unless lecture.open_exam_registration_for(user)

      Action.new(
        kind: "exam",
        icon: "bi-pencil-square",
        label: t("dashboard.quick_actions.exam.label"),
        href: lecture_path(lecture)
      )
    end

    # Forum and comment activity share one bubble since both link to the lecture page.
    def activity_action
      parts = activity_parts
      return if parts.empty?

      Action.new(
        kind: "activity",
        icon: "bi-chat-left-text",
        label: parts.to_sentence,
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
