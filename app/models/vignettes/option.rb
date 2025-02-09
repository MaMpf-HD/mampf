module Vignettes
  class Option < ApplicationRecord
    belongs_to :question, inverse_of: :options, foreign_key: "vignettes_question_id"
    has_and_belongs_to_many :answers,
                            class_name: "Vignettes::Answer",
                            join_table: :vignettes_answers_options,
                            association_foreign_key: "vignettes_answer_id",
                            foreign_key: "vignettes_option_id"
    validates :text, presence: true
  end
end
