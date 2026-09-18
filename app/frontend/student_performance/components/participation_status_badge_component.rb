# Renders a badge indicating the participation status of a student in an assessment,
# with different styles for full and compact variants.
class ParticipationStatusBadgeComponent < ViewComponent::Base
  include ActiveSupport::NumberHelper

  # :icon is the full badge without its word, for a narrow column; the word
  # and whatever detail the row hands over travel in the tooltip.
  VARIANTS = [:full, :compact, :icon].freeze

  STATUS_CONFIG = {
    reviewed: { icon: "bi-check-circle-fill", color: "success" },
    pending_grading: { icon: "bi-hourglass-split", color: "warning-emphasis" },
    not_due: { icon: "bi-dash", color: "muted" },
    not_submitted: { icon: "bi-x-circle-fill", color: "danger" },
    awaiting_record: { icon: "bi-hourglass", color: "muted" },
    absent: { icon: "bi-person-slash", color: "secondary" },
    exempt: { icon: "bi-dash-circle", color: "secondary" }
  }.freeze

  COMPACT_SYMBOLS = {
    pending_grading: { text: "\u2013", color: "warning-emphasis" },
    not_due: { text: "\u2013", color: "muted" },
    not_submitted: { text: "\u2717", color: "muted" },
    awaiting_record: { text: "\u2026", color: "muted" },
    exempt: { text: "\u25CB", color: "muted" },
    absent: { text: "\u00B7", color: "muted" }
  }.freeze

  attr_reader :status, :variant, :points

  def initialize(status:, variant: :full, points: nil, detail: nil)
    super()
    @status = status.to_sym
    @variant = variant.to_sym
    @points = points
    @detail = detail
  end

  def icon_title
    @detail.present? ? "#{label}: #{@detail}" : label
  end

  def config
    STATUS_CONFIG[@status] || STATUS_CONFIG[:not_submitted]
  end

  def label
    I18n.t("student_performance.records.columns.#{@status}")
  end

  def text_class
    ["text", config[:color]].join("-")
  end

  def icon_class
    ["bi", config[:icon], "me-1"].join(" ")
  end

  def tooltip(assessment_title)
    case @status
    when :reviewed
      max = yield if block_given?
      pts = format_points(@points)
      max_str = format_points(max)
      points_label = I18n.t(
        "student_performance.records.tooltip_points"
      )
      "#{assessment_title}: #{pts}/#{max_str} #{points_label}"
    else
      "#{assessment_title}: #{label}"
    end
  end

  def render_compact
    if @status == :reviewed
      format_points(@points)
    else
      display = COMPACT_SYMBOLS[@status] || COMPACT_SYMBOLS[:not_submitted]
      tag.span(class: "text-#{display[:color]}") do
        safe_join([
                    tag.span(display[:text], aria: { hidden: true }),
                    tag.span(label, class: "visually-hidden")
                  ])
      end
    end
  end

  private

    def format_points(value)
      number_to_rounded(
        value || 0, precision: 1, strip_insignificant_zeros: true
      )
    end
end
