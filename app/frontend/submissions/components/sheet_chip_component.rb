# The badge a sheet wears where its points column has no number to show. The
# list and the card say the same thing about the same sheet, so they say it from
# here.
class SheetChipComponent < ViewComponent::Base
  # Grey says "nothing to do yet", amber "this is on you", red "this cost you
  # points". Never green: a sheet coming back is not an achievement.
  TONES = {
    nothing_handed_in: "act",
    grace_period: "act",
    tutor_decides: "act",
    handed_in: "wait",
    awaiting_marks: "wait",
    correction_uploaded: "wait",
    exempt: "wait"
  }.freeze

  def self.for?(state)
    TONES.key?(state)
  end

  attr_reader :sheet

  def initialize(sheet:)
    super()
    @sheet = sheet
  end

  def render?
    self.class.for?(state)
  end

  def state
    @state ||= sheet.state
  end

  def css_class
    "chip chip-#{TONES[state]}"
  end

  def label
    t("submission.hub.chips.#{state}", **interpolations)
  end

  private

    # Only the grace period needs one, and the note under the sheet name wants
    # the same words, which is why it is worked out here rather than inline.
    def interpolations
      return {} unless state == :grace_period

      { time: distance_of_time_in_words(Time.zone.now,
                                        sheet.assignment.friendly_deadline) }
    end
end
