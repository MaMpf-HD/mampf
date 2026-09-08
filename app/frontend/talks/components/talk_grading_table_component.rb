class TalkGradingTableComponent < ViewComponent::Base
  def initialize(seminar:)
    super()
    @seminar = seminar
    @talks = seminar.talks.includes(:speakers, :assessment)
    return unless @talks.any?

    @config = Assessment::DisplayConfigResolver.resolve(
      assessable: @talks.first, grading_scope: @grading_scope
    )
  end

  def grading_enabled?
    true
  end

  def gradable_talks
    @gradable_talks ||= @talks.select { |t| t.speakers.any? && t.assessment.present? }
  end

  def legacy_talks
    @legacy_talks ||= @talks.select { |t| t.speakers.any? && t.assessment.blank? }
  end

  def possible_statuses
    ["pending", "reviewed"]
  end

  delegate :init_participation, to: :"Assessment::TalkGraderService"

  def grade_form_url(talk, user)
    helpers.grade_talk_user_path(talk, user)
  end

  def refresh_form_url(talk, user)
    helpers.refresh_grade_talk_user_path(talk, user)
  end

  def sticky_layout
    return unless @config

    @sticky_layout ||= Assessment::StickyColumnLayout.new(
      left_columns: @config.left_columns,
      right_columns: @config.right_columns
    )
  end

  def sticky_css_vars
    return unless @config

    left = sticky_layout.left_offsets.map { |k, v| "--#{k}-left:#{v}px" }
    right = sticky_layout.right_offsets.map { |k, v| "--#{k}-right:#{v}px" }
    edges = [
      "--sticky-left-width:#{sticky_layout.total_left_width}px",
      "--sticky-right-width:#{sticky_layout.total_right_width}px"
    ]
    (left + right + edges).join(";")
  end
end
