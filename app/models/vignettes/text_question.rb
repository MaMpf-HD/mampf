module Vignettes
  class TextQuestion < Question
    def answer_class
      Vignettes::TextAnswer
    end
  end
end
