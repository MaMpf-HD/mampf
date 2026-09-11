module Vignettes
  class LikertScaleAnswer < Answer
    validates :likert_scale_value,
              inclusion: { in: LikertScaleQuestion::LIKERT_ENUM.keys.map(&:to_s) }
  end
end
