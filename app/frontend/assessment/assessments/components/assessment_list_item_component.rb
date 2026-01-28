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

  def assessable_type
    assessable.is_a?(Talk) ? I18n.t("assessment.talk") : I18n.t("assessment.assignment")
  end

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

  def participations_count
    assessment&.assessment_participations&.count || 0
  end

  def speaker_names
    return nil unless assessable.is_a?(Talk) && assessable.speakers.any?

    assessable.speakers.map(&:name).join(", ")
  end

  def talk_date
    return nil unless assessable.is_a?(Talk) && assessable.dates.any?

    I18n.l(assessable.dates.first, format: :long)
  end

  def badge_class
    return "bg-secondary" if legacy
    return "bg-success" if assessment&.results_published?

    "bg-warning text-dark"
  end

  def badge_text
    return I18n.t("assessment.legacy") if legacy
    return I18n.t("assessment.results_published") if assessment&.results_published?

    I18n.t("assessment.draft")
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
