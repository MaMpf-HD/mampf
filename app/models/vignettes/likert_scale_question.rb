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
      strongly_disagree: "Not at all",
      disagree: "very little",
      agree: "somewhat",
      strongly_agree: "To greater extend"
    }.freeze
    LIKERT_LABELS_DE = {
      strongly_disagree: "Überhaupt nicht",
      disagree: "Sehr wenig",
      agree: "Etwas",
      strongly_agree: "In größerem Umfang"
    }.freeze
    LIKERT_LABELS_NL = {
      strongly_disagree: "helmaal niet",
      disagree: "zeer weinig",
      agree: "enigszins",
      strongly_agree: "in grotere mate"
    }.freeze
  end
end
