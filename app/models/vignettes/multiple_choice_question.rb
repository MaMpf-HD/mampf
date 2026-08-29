module Vignettes
  class MultipleChoiceQuestion < Question
    def answer_class
      Vignettes::MultipleChoiceAnswer
    end
  end
end
