module Dashboard
  # The strip of tape that holds one card onto the dashboard's pinboard.
  #
  # The colour is the student's own choice and is stored in a CardStyle. A card
  # nobody has styled yet still gets a strip, picked deterministically from a
  # seed, so that an untouched dashboard already looks like a hand-arranged
  # board instead of a stack of identical strips — and so that the strip stays
  # put across reloads instead of flickering to a new colour.
  class WashiTape
    COLORS = ["butter", "rose", "mint", "sky", "lavender", "clay"].freeze

    # Coprime to the number of colours, so neighbouring seeds (consecutive
    # lecture ids) step through the list instead of repeating a colour.
    COLOR_STRIDE = 5

    # Degrees the strip is tilted against the card it holds. Small enough to
    # read as "stuck on by hand", large enough to be noticeable.
    MAX_TILT = 6

    def self.for(seed:, color: nil)
      new(seed: seed, color: color)
    end

    def initialize(seed:, color: nil)
      @seed = seed.to_i.abs
      @color = color.presence_in(COLORS) || COLORS[@seed * COLOR_STRIDE % COLORS.size]
    end

    attr_reader :seed, :color

    # Whole degrees in [-MAX_TILT, MAX_TILT], derived from the seed so the
    # strip does not jump to a new angle on every render.
    def tilt
      @tilt ||= (seed * 29 % ((2 * MAX_TILT) + 1)) - MAX_TILT
    end
  end
end
