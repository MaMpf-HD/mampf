# The paper card that both lectures and talks are shown on at the top of the
# dashboard: a photo, a title, a line of small print underneath, and a strip of
# washi tape holding it to the board.
#
# Everything that differs between a lecture and a talk goes in through the
# slots, so the two card components stay a description of their subject and
# this one owns the look. Anything else the caller needs on the card element
# itself (test hooks, the lecture id) is passed through as `attributes`.
class DashboardCardComponent < ViewComponent::Base
  # The line of small print under the title: the lecturer, the term, …
  renders_one :subtitle

  # Sits above the tape and the photo, for the small controls that must stay
  # clickable over the card-wide title link.
  renders_one :corner

  # Short lines of status below the title: deadlines, registration state, …
  renders_many :notes

  # A wider piece of status under the notes, such as the points bar.
  renders_one :progress

  # The quick actions pinned beside the card. They sit outside the card rather
  # than on it, because the card's title link is stretched over the whole card
  # and would swallow anything clickable inside it.
  renders_one :rail

  # Whole degrees the card is rotated on the board, in half-degree steps and
  # small enough to stay readable. Kept apart from the tape's own tilt so the
  # strip does not sit square on a card that is itself askew.
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

  # The card's own border and its tape are dyed the same colour, so the colour
  # is set here once and both read it from the card.
  def style
    "--dashboard-card-tilt: #{tilt}deg; " \
      "--washi-tape-color: var(--washi-tape-color-#{tape.color})"
  end
end
