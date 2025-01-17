module Vignettes
  class LikertScaleQuestion < Question
    LIKERT_OPTIONS = {
      5 => "Strongly Agree",
      4 => "Agree",
      3 => "Neither agree nor disagree",
      2 => "Disagree",
      1 => "Strongly Disagree"
    }.freeze
  end
end
