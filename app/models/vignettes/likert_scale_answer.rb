module Vignettes
  class LikertScaleAnswer < Answer
    enum likert_scale_value: Vignettes::LikertScaleQuestion::LIKERT_ENUM
  end
end
