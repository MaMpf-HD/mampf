# One row of the sheet list: the sheet's name, a badge, and the reader's points.
# The two state columns never both speak - a badge stands exactly where the
# points column has no number to show, and the number is the status everywhere
# else.
class SheetRowComponent < ViewComponent::Base
  include ActiveSupport::NumberHelper

  # Grey says "nothing to do yet", amber "this is on you", red "this cost you
  # points". Never green: a sheet coming back is not an achievement.
  CHIP_TONES = {
    nothing_handed_in: "act",
    grace_period: "act",
    tutor_decides: "act",
    handed_in: "wait",
    awaiting_marks: "wait",
    correction_uploaded: "wait",
    exempt: "wait"
  }.freeze

  # The quiet line under the sheet name, and only where a row would otherwise
  # be unexplained. `:bad` is the red one, kept for the two states where the
  # zero was nobody's doing and the reader has something to take up with
  # somebody.
  NOTE_TONES = {
    grace_period: :quiet,
    tutor_decides: :quiet,
    partially_marked: :quiet,
    missed: :quiet,
    absent: :quiet,
    exempt: :quiet,
    not_recorded: :bad,
    rejected: :bad
  }.freeze

  NUMBER_STATES = [:marked, :partially_marked, :absent, :missed,
                   :not_recorded, :rejected].freeze
  ZERO_STATES = [:absent, :missed, :not_recorded, :rejected].freeze

  attr_reader :sheet

  def initialize(sheet:)
    super()
    @sheet = sheet
  end

  def state
    @state ||= sheet.state
  end

  # Sheets from before points existed. The row is dimmed and says so in words,
  # because a colour alone would leave it looking like a failure.
  def legacy?
    state == :no_points
  end

  # The dimming sits on the whole entry, so the fold goes quiet with the row.
  def entry_class
    ["sheet-entry", ("sheet-muted" if legacy?)].compact.join(" ")
  end

  def chip_class
    tone = CHIP_TONES[state]
    "chip chip-#{tone}" if tone
  end

  def chip_label
    return unless CHIP_TONES.key?(state)

    t("submission.hub.chips.#{state}", **interpolations)
  end

  def points_class
    ["text-end", "num", ("num-none" unless number?)].compact.join(" ")
  end

  def note
    return t("submission.hub.notes.accepted_late") if accepted_late_note?
    return unless NOTE_TONES.key?(state)

    t("submission.hub.notes.#{state}", **interpolations)
  end

  def note_class
    return "sheet-note" if accepted_late_note?

    NOTE_TONES[state] == :bad ? "sheet-note-bad" : "sheet-note"
  end

  def number?
    state.in?(NUMBER_STATES)
  end

  def zero?
    state.in?(ZERO_STATES)
  end

  # `:exempt` is the one state that has no denominator either: the sheet was
  # taken out of the reckoning, so "of 16" would claim it still counts.
  def maximum?
    state != :exempt
  end

  def points
    format_number(sheet.points)
  end

  def max_points
    format_number(sheet.max_points)
  end

  # What a screen reader gets instead of "6.5 slash 16", which is why the
  # visible figure is hidden from it.
  def points_reader_label
    t("submission.hub.points_reader", points: points, max: max_points)
  end

  # The bar is an underline under the number, never a figure of its own, so it
  # is drawn only where there is a ratio to draw.
  def bar_percentage
    return unless number?
    return if sheet.max_points.nil? || sheet.max_points.zero?

    [(sheet.points.to_f / sheet.max_points * 100).round(2), 100].min
  end

  private

    def accepted_late_note?
      state == :marked && sheet.accepted_late?
    end

    # Only the grace period needs one, and both its badge and its note want it.
    def interpolations
      return {} unless state == :grace_period

      { time: distance_of_time_in_words(Time.zone.now,
                                        sheet.assignment.friendly_deadline) }
    end

    def format_number(value)
      number_to_rounded(value || 0, precision: 2,
                                    strip_insignificant_zeros: true)
    end
end
