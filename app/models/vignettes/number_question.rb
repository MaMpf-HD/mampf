module Vignettes
  class NumberQuestion < Question
    def answer_class
      Vignettes::NumberAnswer
    end
  end
end
