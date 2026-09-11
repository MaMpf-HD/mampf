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

  def grade_form_url(participation)
    helpers.grade_participation_path(participation)
  end

  def refresh_form_url(participation)
    helpers.refresh_grade_participation_path(participation)
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

    helpers.sticky_css_vars_calc(sticky_layout)
  end
end
