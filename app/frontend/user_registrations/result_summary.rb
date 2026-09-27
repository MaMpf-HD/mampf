# Presents a student's own published exam or talk result, so that the lecture
# home's block for a new result and the participation row say the same.
class ResultSummary
  Task = Struct.new(:label, :points, :max_points, keyword_init: true)

  attr_reader :participation

  def initialize(participation)
    @participation = participation
  end

  def title
    participation.assessment.title
  end

  delegate :absent?, :exempt?, to: :participation

  def grade
    return participation.grade_text.presence unless participation.grade_numeric

    ActiveSupport::NumberHelper.number_to_rounded(participation.grade_numeric, precision: 1,
                                                                               locale: I18n.locale)
  end

  def grade_line
    I18n.t("registration.user_registration.participation.grade", grade: grade)
  end

  # An absent student may still carry a grade, so it is named beside "absent".
  def lines
    [(grade_line if absent? && grade), points_line].compact
  end

  def points_line
    return unless tasks.any?

    I18n.t("registration.user_registration.participation.points",
           points: format_points(participation.points_total || 0),
           total: format_points(participation.assessment.effective_total_points))
  end

  def tasks
    return [] unless participation.reviewed?

    @tasks ||= begin
      points = participation.task_points.index_by(&:task_id)
      participation.assessment.tasks.sort_by(&:position).each_with_index.map do |task, index|
        Task.new(label: task.description.presence ||
                        I18n.t("registration.user_registration.participation.problem",
                               number: index + 1),
                 points: points[task.id]&.points&.then { |value| format_points(value) },
                 max_points: format_points(task.max_points || 0))
      end
    end
  end

  private

    def format_points(value)
      ActiveSupport::NumberHelper.number_to_rounded(value, precision: 2,
                                                           strip_insignificant_zeros: true,
                                                           locale: I18n.locale)
    end
end
