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

  def marked?
    statistics.counts[:marked].positive?
  end

  def grades?
    statistics.grades.number.positive?
  end

  def group_tables
    return {} unless marked? || grades?

    { programs: statistics.program_rows, tutorials: statistics.tutorial_rows }
      .reject { |_key, rows| rows.empty? }
  end

  def format_points(value)
    return "—" if value.nil?

    helpers.number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
  end

  def format_share(share)
    return "—" if share.nil?

    helpers.number_to_percentage(share * 100, precision: 0)
  end

  def format_grade(value)
    return "—" if value.nil?

    helpers.number_with_precision(value, precision: 1)
  end

  def share_of(mean, max)
    return if mean.nil? || max.to_f.zero?

    mean / max.to_f
  end

  def task_label(task)
    "#{t("assessment.grading_tutorial.task")} #{task.position}"
  end

  def grade_count_bar(count, total)
    helpers.progress_bar(count, [total, 1].max, label: count.to_s, height: "1rem",
                                                container_class: "progress")
  end

  def share_bar(share)
    return if share.nil?

    helpers.progress_bar((share * 100).round, 100, label: format_share(share),
                                                   height: "1rem", container_class: "progress")
  end
end
