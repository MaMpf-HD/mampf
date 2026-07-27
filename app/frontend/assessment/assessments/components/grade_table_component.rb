class GradeTableComponent < ViewComponent::Base
  include ActionView::Helpers::DateHelper

  def initialize(assessment:)
    super()
    @assessment = assessment
  end

  attr_reader :assessment

  def displayed_participations
    @displayed_participations ||= assessment.assessment_participations
                                            .joins(:user)
                                            .includes(:user, :tutorial, :grader)
                                            .where(status: [:pending, :reviewed, :absent, :exempt])
                                            .order("users.name")
  end

  def any_displayed?
    displayed_participations.any?
  end

  def show_tutorial_column?
    assessment.assessable.is_a?(Assignment)
  end

  def show_grader_column?
    displayed_participations.pluck(:grader_id).compact.uniq.size > 1
  end

  def status_label(participation)
    I18n.t("assessment.grade_table.#{participation.status}")
  end

  def absent_grade_display(participation)
    participation.grade_numeric ? participation.grade_numeric.to_s : "5.0"
  end

  def grade_display(participation)
    return "—" unless participation.grade_numeric

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
end
