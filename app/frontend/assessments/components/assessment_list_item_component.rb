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

    assessment_assessment_path(assessment.id)
  end

  def visible_from
    return nil unless assessment&.visible_from

    I18n.l(assessment.visible_from, format: :short)
  end

  def due_at
    return nil unless assessment&.due_at

    I18n.l(assessment.due_at, format: :short)
  end

  def tasks_count
    assessment&.tasks&.count || 0
  end

  def participations_count
    assessment&.assessment_participations&.count || 0
  end

  def badge_class
    return "bg-secondary" if legacy
    return "bg-success" if assessment&.open? || assessment&.closed?

    "bg-warning text-dark"
  end

  def badge_text
    return I18n.t("assessment.legacy") if legacy

    return I18n.t("assessment.status.#{assessment.status}") if assessment

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
