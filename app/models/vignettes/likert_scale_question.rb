module Vignettes
  class LikertScaleQuestion < Question
    LIKERT_ENUM = {
      strongly_disagree: 1,
      disagree: 2,
      neither_agree_nor_disagree: 3,
      agree: 4,
      strongly_agree: 5
    }.freeze

    LIKERT_LABELS = {
      strongly_disagree: "Strongly Disagree",
      disagree: "Disagree",
      neither_agree_nor_disagree: "Neither agree nor disagree",
      agree: "Agree",
      strongly_agree: "Strongly Agree"
    }.freeze
  end
end
