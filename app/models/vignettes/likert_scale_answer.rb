module Vignettes
  class LikertScaleAnswer < Answer
    enum likert_scale_value: {
      strongly_agree: 5,
      agree: 4,
      neither_agree_nor_disagree: 3,
      disagree: 2,
      strongly_disagree: 1
    }
  end
end
