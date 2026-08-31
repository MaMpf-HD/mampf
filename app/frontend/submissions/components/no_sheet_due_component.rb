# The action block when nothing can be handed in: what is coming, and what came
# back most recently. The block is repurposed rather than removed - an empty
# space where the reader looks first says nothing at all.
class NoSheetDueComponent < ViewComponent::Base
  include ActiveSupport::NumberHelper

  attr_reader :next_scheduled, :latest_marked

  # `next_scheduled` is a `Lecture::ScheduledSheet` or nil. The date is not
  # guessed: when nothing is scheduled the block says so.
  def initialize(next_scheduled: nil, latest_marked: nil)
    super()
    @next_scheduled = next_scheduled
    @latest_marked = latest_marked
  end

  def next_sheet_line
    return t("submission.hub.card.nothing_scheduled") unless next_scheduled

    unless next_scheduled.deadline
      return appears_line(next_scheduled.title, next_scheduled.release_date)
    end

    t("submission.hub.card.appears_until",
      sheet: next_scheduled.title,
      date: at(next_scheduled.release_date),
      deadline: at(next_scheduled.deadline))
  end

  def points
    format_number(latest_marked.points)
  end

  def max_points
    format_number(latest_marked.max_points)
  end

  def points_reader_label
    t("submission.hub.points_reader", points: points, max: max_points)
  end

  def bar_percentage
    max = latest_marked.max_points
    return if max.nil? || max.zero?

    [(latest_marked.points.to_f / max * 100).round(2), 100].min
  end

  def correction_name
    latest_marked.submission&.correction_filename
  end

  private

    def appears_line(title, release)
      t("submission.hub.card.appears", sheet: title, date: at(release))
    end

    def at(time)
      l(time, format: :submission_deadline)
    end

    def format_number(value)
      number_to_rounded(value || 0, precision: 2,
                                    strip_insignificant_zeros: true)
    end
end
