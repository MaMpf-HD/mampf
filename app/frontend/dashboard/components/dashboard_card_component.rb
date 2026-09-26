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
    @tilt ||= Dashboard::Tilt.for(tape.seed, max: MAX_TILT, stride: 37, step: 0.5)
  end

  def style
    "--dashboard-card-tilt: #{tilt}deg; " \
      "--washi-tape-color: var(--washi-tape-color-#{tape.color})"
  end
end
