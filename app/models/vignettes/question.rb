module Vignettes
  class Question < ApplicationRecord
    TEXT_MIN_LENGTH = 1
    TEXT_MAX_LENGTH = 5_000
    validates(:question_text,
              presence: true,
              length: { minimum: TEXT_MIN_LENGTH, maximum: TEXT_MAX_LENGTH },
              if: :question_text_required?)

    # Uses single table inheritance to store different types of answers
    belongs_to :slide, inverse_of: :question, foreign_key: "vignettes_slide_id"
    has_many :options, dependent: :destroy, inverse_of: :question
    has_many :answers, dependent: :destroy, inverse_of: :question

    accepts_nested_attributes_for :options, allow_destroy: true, reject_if: :all_blank

    self.abstract_class = false

    # Answers are single table inheritance too, and each kind of question takes
    # exactly one kind of them.
    def answer_class
      raise(NotImplementedError, "#{self.class} does not say which answer it takes")
    end

    def question_text_required?
      type.present? && type != ""
    end
  end
end
