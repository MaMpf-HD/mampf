# Paper card shown on the dashboard: photo, title, subtitle, and washi tape.
# Lecture and talk specifics come in through slots.
class DashboardCardComponent < ViewComponent::Base
  renders_one :subtitle
  renders_one :corner
  renders_many :notes
  renders_one :progress
  renders_one :rail

  MAX_TILT = 2.5

  def initialize(href:, image_url:, title:, tape:, **attributes)
    super()
    @href = href
    @image_url = image_url
    @title = title
    @tape = tape
    @attributes = attributes
  end

  attr_reader :href, :image_url, :title, :tape, :attributes

  def tilt
    @tilt ||= ((tape.seed * 37 % ((4 * MAX_TILT) + 1)) - (2 * MAX_TILT)) / 2.0
  end

  def style
    "--dashboard-card-tilt: #{tilt}deg; " \
      "--washi-tape-color: var(--washi-tape-color-#{tape.color})"
  end
end
