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
    return "#" if assessable.is_a?(Talk)

    assessment_assessment_path(
      assessment.id,
      assessable_type: assessable.class.name,
      assessable_id: assessable.id
    )
  end

  def clickable?
    !legacy && assessable.is_a?(Assignment) && assessment.present?
  end

  def medium_title
    return nil unless assessable.respond_to?(:medium) && assessable.medium

    assessable.medium.local_title_for_viewers
  end

  def file_type
    return nil unless assessable.respond_to?(:accepted_file_type)

    assessable.accepted_file_type
  end

  def deletion_date
    return nil unless assessable.respond_to?(:deletion_date) && assessable.deletion_date

    I18n.l(assessable.deletion_date, format: :long)
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
