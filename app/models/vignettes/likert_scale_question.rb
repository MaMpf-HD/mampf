module Vignettes
  class LikertScaleQuestion < Question
    LIKERT_ENUM = {
      strongly_disagree: 1,
      disagree: 2,
      agree: 3,
      strongly_agree: 4
    }.freeze

    def labels
      case language&.to_s&.downcase
      when "de"
        LIKERT_LABELS_DE
      when "nl"
        LIKERT_LABELS_NL
      else
        LIKERT_LABELS_EN
      end
    end

    LIKERT_LABELS_EN = {
      strongly_disagree: "No alignment at all",
      disagree: "Little alignment",
      agree: "Quite some alignment",
      strongly_agree: "Complete alignment"
    }.freeze
    LIKERT_LABELS_DE = {
      strongly_disagree: "Überhaupt keine Übereinstimmung",
      disagree: "Geringe Übereinstimmung",
      agree: "Ziemlich große Übereinstimmung",
      strongly_agree: "Vollständige Übereinstimmung"
    }.freeze
    LIKERT_LABELS_NL = {
      strongly_disagree: "Helemaal geen overeenstemming",
      disagree: "Weinig overeenstemming",
      agree: "Wogal wat overeenstemming",
      strongly_agree: "Volledige overeenstemming"
    }.freeze
  end
end
