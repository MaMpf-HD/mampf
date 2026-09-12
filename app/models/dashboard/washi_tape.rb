module Dashboard
  # Tilt and color for a dashboard card's tape strip. Color defaults to a
  # deterministic pick from the seed, so an untouched card still gets a
  # stable, varied color instead of always the same one.
  class WashiTape
    COLORS = ["butter", "rose", "mint", "sky", "lavender", "peach"].freeze
    COLOR_STRIDE = 5 # coprime to COLORS.size, so consecutive seeds don't repeat
    MAX_TILT = 6

    def self.for(seed:, color: nil)
      new(seed: seed, color: color)
    end

    def initialize(seed:, color: nil)
      @seed = seed.to_i.abs
      @color = color.presence_in(COLORS) || COLORS[@seed * COLOR_STRIDE % COLORS.size]
    end

    attr_reader :seed, :color

    def tilt
      @tilt ||= (seed * 29 % ((2 * MAX_TILT) + 1)) - MAX_TILT
    end
  end
end
