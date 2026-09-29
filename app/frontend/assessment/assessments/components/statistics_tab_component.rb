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
    figure_with_bar(count.to_s, count, [total, 1].max)
  end

  def share_bar(share)
    return if share.nil?

    figure_with_bar(format_share(share), (share * 100).round, 100)
  end

  private

    def figure_with_bar(figure, value, max)
      tag.div(class: "d-flex align-items-center gap-2") do
        tag.span(figure, class: "text-nowrap text-end statistics-figure") +
          tag.div(class: "flex-grow-1", "aria-hidden": true) do
            helpers.progress_bar(value, max, show_label: false, height: "0.5rem",
                                             container_class: "progress statistics-bar")
          end
      end
    end
end
