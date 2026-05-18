module Vignettes
  class NumberAnswer < Answer
    NUM_MIN_LENGTH = 1
    NUM_MAX_LENGTH = 500

    validates :text, length: { minimum: NUM_MIN_LENGTH,
                               maximum: NUM_MAX_LENGTH },
                     allow_blank: false,
                     numericality: true
  end
end
