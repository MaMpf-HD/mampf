module Vignettes
  class Answer < ApplicationRecord
    belongs_to :question, class_name: "Vignettes::Question", foreign_key: "vignettes_question_id"
    belongs_to :slide, class_name: "Vignettes::Slide", foreign_key: "vignettes_slide_id"

    has_one :slide_statistic, class_name: "Vignettes::SlideStatistic",
                              foreign_key: "vignettes_answer_id",
                              inverse_of: :answer, dependent: :destroy

    accepts_nested_attributes_for :slide_statistic, allow_destroy: true

    belongs_to :user_answer, class_name: "Vignettes::UserAnswer",
                             foreign_key: "vignettes_user_answer_id"

    has_and_belongs_to_many :options,
                            class_name: "Vignettes::Option",
                            join_table: :vignettes_answers_options,
                            association_foreign_key: "vignettes_option_id",
                            foreign_key: "vignettes_answer_id"
  end
end
