# The statistics tab of a sheet or an exam: how the hand-ins stand, then how
# the marks spread (see Assessment::Statistics).
class StatisticsTabComponent < ViewComponent::Base
  def initialize(assessment:, lecture:)
    super()
    @assessment = assessment
    @lecture = lecture
  end

  attr_reader :assessment, :lecture

  def show_submissions?
    assessment&.requires_submission
  end

  def statistics
    @statistics ||= Assessment::Statistics.new(assessment)
  end

  def number(value, precision: 1)
    return "—" if value.nil?

    helpers.number_with_precision(value, precision: precision,
                                         strip_insignificant_zeros: true)
  end

  def percent(share)
    return "—" if share.nil?

    helpers.number_to_percentage(share * 100, precision: 0)
  end

  def grade(value)
    return "—" if value.nil?

    helpers.number_with_precision(value, precision: 1)
  end

  def share_of_max(value)
    return if value.nil? || statistics.max_points.zero?

    value / statistics.max_points
  end

  def task_share(row)
    max = row.task.max_points.to_f
    return if row.figures.mean.nil? || max.zero?

    row.figures.mean / max
  end

  def task_label(task)
    "#{t("assessment.grading_tutorial.task")} #{task.position}"
  end

  def grades?
    statistics.grades.number.positive?
  end

  def bar(count, total)
    helpers.progress_bar(count, [total, 1].max, label: count.to_s, height: "1rem",
                                                container_class: "progress")
  end
end
