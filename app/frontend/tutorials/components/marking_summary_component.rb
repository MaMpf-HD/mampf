# One line saying where the sheet stands, counted off the rows' own display
# statuses.
class MarkingSummaryComponent < ViewComponent::Base
  PARTS = [:reviewed, :pending_grading, :not_submitted, :awaiting_record,
           :met, :not_met, :unmarked, :exempt, :absent].freeze

  # A talk's rows have nothing handed in to count. An exam draws two tables
  # on one page, so the second line needs an id of its own to be replaced.
  attr_reader :id

  def initialize(statuses:, hand_ins: true, id: "marking-summary", extra_parts: [])
    super()
    @statuses = statuses
    @hand_ins = hand_ins
    @id = id
    @extra_parts = extra_parts
  end

  def text
    counts = @statuses.tally
    parts = []
    if @hand_ins
      handed_in = counts.fetch(:reviewed, 0) + counts.fetch(:pending_grading, 0)
      parts << I18n.t("assessment.grading_tutorial.summary.handed_in", count: handed_in)
    end
    PARTS.each do |status|
      next unless counts[status]&.positive?

      parts << I18n.t("assessment.grading_tutorial.summary.#{status}", count: counts[status])
    end
    (parts + @extra_parts).join(" · ")
  end

  def call
    tag.p(text, id: @id, class: "text-muted small mb-2")
  end
end
