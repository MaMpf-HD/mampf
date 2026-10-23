# Speech bubbles beside a lecture's card, one per actionable item (a new
# result, deadlines, open exam registration, unread activity). Purely
# informational state stays on the card itself.
class LectureQuickActionsComponent < ViewComponent::Base
  DUE_SOON_WINDOW = 7.days
  MAX_TILT = 1.5

  Action = Struct.new(:kind, :icon, :label, :href, :links, keyword_init: true)
  Link = Struct.new(:kind, :label, :href, keyword_init: true)

  # `staff` keeps only the unread activity, since results, deadlines and exam
  # registration are student actions.
  def initialize(lecture:, user:, activity: nil, staff: false)
    super()
    @lecture = lecture
    @user = user
    @activity = activity
    @staff = staff
  end

  attr_reader :lecture, :user, :staff
  alias staff? staff

  def render?
    actions.any?
  end

  def actions
    @actions ||= if staff?
      [activity_action].compact
    else
      [result_action, assignment_action, exam_registration_action, activity_action].compact
    end
  end

  def list_label
    t("dashboard.quick_actions.list_label", lecture: lecture.title_no_term)
  end

  def tilt(index)
    magnitude = Dashboard::Tilt.for(lecture.id + (index * 7), max: MAX_TILT,
                                                              stride: 1, step: 0.5).abs
    magnitude * (index.even? ? 1 : -1)
  end

  def style(index)
    "--quick-action-tilt: #{tilt(index)}deg"
  end

  # The links of a bubble with several, as one sentence ("… and …"), each
  # naming the lecture for screen readers like a bubble that is one link.
  def links_sentence(action)
    to_sentence(action.links.map do |link|
      link_to(link.href, class: "quick-action__link",
                         data: { testid: "quick-action-#{link.kind}" }) do
        safe_join([link.label, tag.span(lecture.title_no_term, class: "visually-hidden")], " ")
      end
    end)
  end

  private

    def activity
      @activity ||= Dashboard::LectureActivity.new(user: user,
                                                   lectures: [lecture])
    end

    # Leads to the lecture home. Once the student closes the result's block
    # there (result_seen_at), the bubble is gone as well.
    def result_action
      titles = Assessment::Participation.new_results_for(user, lecture)
                                        .map { |participation| participation.assessment.title }
      return if titles.empty?

      Action.new(
        kind: "result",
        icon: "bi-award",
        label: t("dashboard.quick_actions.result.label", count: titles.size, title: titles.first),
        href: lecture_path(lecture)
      )
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

    # Forum and comments share one bubble, with a link to each, since they
    # lead to different pages.
    def activity_action
      links = [forum_link, comments_link].compact
      return if links.empty?

      Action.new(kind: "activity", icon: "bi-chat-left-text", links: links)
    end

    def forum_link
      count = activity.unread_forum_topics(lecture)
      return unless count.positive?

      Link.new(kind: "forum",
               label: t("dashboard.quick_actions.activity.forum", count: count),
               href: "/forum/#{lecture.forum.slug}")
    end

    def comments_link
      count = activity.unread_comments(lecture)
      return unless count.positive?

      Link.new(kind: "comments",
               label: t("dashboard.quick_actions.activity.comments", count: count),
               href: comments_path(lecture_id: lecture.id))
    end
end
