# Washi tape strip across the top of a dashboard card. With an `update_url`
# it becomes a color picker button; without one it's decoration (talk cards).
class WashiTapeComponent < ViewComponent::Base
  def initialize(tape:, label: nil, update_url: nil)
    super()
    @tape = tape
    @label = label
    @update_url = update_url
  end

  attr_reader :tape, :label, :update_url

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

  def strip_style
    "--washi-tape-tilt: #{tape.tilt}deg"
  end

  def color_style(color)
    "--washi-tape-color: var(--washi-tape-color-#{color})"
  end

  # Unique per card, so one picker's radios don't capture the ones next to it.
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
