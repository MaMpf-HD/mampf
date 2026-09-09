# The strip of washi tape across the top of a dashboard card.
#
# With an `update_url` the strip becomes a button that opens a small picker for
# its colour, and the choice is saved for this user. Without one it is
# decoration and is hidden from assistive technology, which is what talk cards
# get: there is nothing to remember a choice against.
class WashiTapeComponent < ViewComponent::Base
  def initialize(tape:, label: nil, update_url: nil)
    super()
    @tape = tape
    @label = label
    @update_url = update_url
  end

  attr_reader :tape, :label, :update_url

  # The card this strip holds tilts by the same seed and is bordered in the
  # same colour, so both stay tied to the same subject.
  delegate :seed, :color, to: :tape

  def editable?
    update_url.present?
  end

  def wrapper_data
    return {} unless editable?

    { data: { controller: "washi-tape",
              washi_tape_url_value: update_url,
              testid: "washi-tape" } }
  end

  # The colour is set on the card, so that the border can pick it up too; the
  # strip only has to say how far it is tilted against it.
  def strip_style
    "--washi-tape-tilt: #{tape.tilt}deg"
  end

  def color_style(color)
    "--washi-tape-color: var(--washi-tape-color-#{color})"
  end

  # Unique per card, so one picker's radios do not capture the ones next to it.
  # The update path names the lecture, which is what makes them distinct.
  def group_name
    "washi-tape-color-#{update_url.parameterize}"
  end

  def colors
    Dashboard::WashiTape::COLORS
  end

  def color_label(color)
    t("dashboard.washi_tape.colors.#{color}")
  end
end
