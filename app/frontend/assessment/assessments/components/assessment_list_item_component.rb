class AssessmentListItemComponent < ViewComponent::Base
  def initialize(assessable:, lecture:, legacy: false)
    super()
    @assessable = assessable
    @lecture = lecture
    @legacy = legacy
    @assessment = assessable.assessment
  end

  attr_reader :assessable, :lecture, :legacy, :assessment

  delegate :title, to: :assessable

  def show_path
    return "#" unless assessment

    assessment_assessment_path(
      assessment.id,
      assessable_type: assessable.class.name,
      assessable_id: assessable.id
    )
  end

  def clickable?
    !legacy && assessment.present?
  end

  def row_tag_attrs
    attrs = { id: dom_id(assessable), class: ("table-secondary" if legacy) }
    if clickable?
      attrs[:data] = { controller: "row-click",
                       action: "click->row-click#visit" }
      attrs[:style] = "cursor: pointer;"
    end
    attrs
  end

  def medium_title
    return nil unless assessable.respond_to?(:medium) && assessable.medium

    assessable.medium.local_title_for_viewers
  end

  def file_type
    return nil unless assessable.respond_to?(:accepted_file_type)

    assessable.accepted_file_type
  end

  def deadline_display
    return nil unless assessable.respond_to?(:deadline) && assessable.deadline

    I18n.l(assessable.deadline, format: :short)
  end

  def tasks_count
    assessment&.tasks&.count || 0
  end

  def total_points
    assessment&.tasks&.sum(:max_points) || 0
  end

  def total_points_display
    return "—" unless assessment&.requires_points
    return "—" if tasks_count.zero?

    formatted = (total_points % 1).zero? ? total_points.to_i : total_points
    "#{formatted} #{I18n.t("assessment.task.points_abbrev")}"
  end

  def requires_submission?
    assessment&.requires_submission
  end

  def grade_display
    return nil unless assessable.is_a?(Talk) && assessment

    parts = assessment.assessment_participations.where.not(grade_numeric: nil)
    return nil if parts.empty?

    parts.map { |p| p.grade_numeric.to_s }.join(", ")
  end

  def speaker_names
    return nil unless assessable.is_a?(Talk) && assessable.speakers.any?

    assessable.speakers.map(&:name).join(", ")
  end

  def talk_date
    return nil unless assessable.is_a?(Talk) && assessable.dates.any?

    I18n.l(assessable.dates.first, format: :long)
  end

  def edit_path
    return nil unless legacy && assessable.is_a?(Assignment)

    edit_assignment_path(assessable)
  end

  def delete_path
    return nil unless legacy && assessable.is_a?(Assignment)

    assignment_path(assessable)
  end
end
