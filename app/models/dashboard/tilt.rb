module Dashboard
  # Turns a seed into a stable tilt between -max and max degrees, in steps of
  # `step`, so a card keeps its slant from one visit to the next. Each caller
  # passes its own stride, so that a card, its tape and its bubbles do not all
  # lean the same way.
  module Tilt
    module_function

    def for(seed, max:, stride:, step: 1)
      steps = (2 * max / step).round
      ((seed * stride % (steps + 1)) - (steps / 2)) * step
    end
  end
end
