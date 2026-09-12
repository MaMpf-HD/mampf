# One line saying where the sheet stands, counted off the rows' own display
# statuses. Rendered with the toolbar and again after any answer that
# changes a row, so it never says something the rows do not.
class PointingSummaryComponent < ViewComponent::Base
  # Where a count is zero the line keeps quiet, except about the hand-ins.
  PARTS = [:reviewed, :pending_grading, :not_submitted, :awaiting_record,
           :exempt, :absent].freeze

  def initialize(statuses:)
    super()
    @statuses = statuses
  end

  def text
    counts = @statuses.tally
    handed_in = counts.fetch(:reviewed, 0) + counts.fetch(:pending_grading, 0)
    parts = [I18n.t("assessment.grading_tutorial.summary.handed_in", count: handed_in)]
    PARTS.each do |status|
      next unless counts[status]&.positive?

      parts << I18n.t("assessment.grading_tutorial.summary.#{status}", count: counts[status])
    end
    parts.join(" · ")
  end

  def call
    tag.p(text, id: "pointing-summary", class: "text-muted small mb-2")
  end
end
