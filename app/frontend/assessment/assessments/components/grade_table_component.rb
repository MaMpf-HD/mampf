# Missing top-level docstring, please formulate one yourself 😁
class GradeTableComponent < ViewComponent::Base
  include ActionView::Helpers::DateHelper

  def initialize(assessment:)
    super()
    @assessment = assessment
  end

  attr_reader :assessment

  def exam?
    assessment.assessable.is_a?(Exam)
  end

  def assignment?
    assessment.assessable.is_a?(::Assignment)
  end

  def talk?
    assessment.assessable.is_a?(Talk)
  end

  def show_tutorial_column?
    assignment?
  end

  def show_points_column?
    assessable = assessment.assessable
    assessable.is_a?(::Assessment::Pointable) &&
      assessable.is_a?(::Assessment::Gradable)
  end

  def show_status_column?
    excluded_participations.any?
  end

  def show_grader_column?
    grader_ids = displayed_participations
                 .pluck(:grader_id)
                 .compact
                 .uniq
    grader_ids.size > 1
  end

  def show_graded_at_column?
    !exam?
  end

  def points_display(participation)
    return "\u2014" unless participation.points_total

    participation.points_total.to_s
  end

  def gradeable_participations
    @gradeable_participations ||=
      participations.where(status: [:pending, :reviewed])
  end

  def absent_participations
    @absent_participations ||= participations.where(status: :absent)
  end

  def exempt_participations
    @exempt_participations ||= participations.where(status: :exempt)
  end

  def excluded_participations
    @excluded_participations ||=
      participations.where(status: [:absent, :exempt])
  end

  def displayed_participations
    @displayed_participations ||=
      participations.where(status: [:pending, :reviewed, :absent, :exempt])
  end

  def any_displayed?
    displayed_participations.any?
  end

  def any_gradeable?
    gradeable_participations.any?
  end

  def any_excluded?
    excluded_participations.any?
  end

  def row_status(participation)
    participation.status.to_sym
  end

  def status_label(participation)
    I18n.t("assessment.grade_table.#{participation.status}")
  end

  def status_badge_class(participation)
    case row_status(participation)
    when :absent then "bg-danger"
    when :exempt then "bg-secondary"
    else "bg-light text-muted"
    end
  end

  def absent_grade_display(participation)
    if participation.grade_numeric
      participation.grade_numeric.to_s
    else
      "5.0"
    end
  end

  def grade_display(participation)
    return "\u2014" unless participation.grade_numeric

    text = participation.grade_text
    numeric = participation.grade_numeric
    if text.present? && text != numeric.to_s
      "#{numeric} (#{text})"
    else
      numeric.to_s
    end
  end

  def grader_display(participation)
    participation.grader&.tutorial_name
  end

  def graded_at_relative(participation)
    return nil unless participation.graded_at

    time_ago_in_words(participation.graded_at)
  end

  def graded_at_full(participation)
    return nil unless participation.graded_at

    I18n.l(participation.graded_at, format: :short)
  end

  def common_grader_name
    grader_ids = gradeable_participations.pluck(:grader_id).compact.uniq
    return nil unless grader_ids.size == 1

    gradeable_participations.find { |p| p.grader_id.present? }
                            &.grader
                            &.tutorial_name
  end

  private

    def participations
      @participations ||= base_participations.order(*sort_clause)
    end

    def base_participations
      assessment.assessment_participations
                .joins(:user)
                .includes(:user, :tutorial, :grader)
    end

    def sort_clause
      if exam?
        ["users.name"]
      else
        [:tutorial_id, "users.name"]
      end
    end
end
