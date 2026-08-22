module Vignettes
  class Questionnaire < ApplicationRecord
    belongs_to :lecture
    has_many :slides,
             foreign_key: "vignettes_questionnaire_id",
             dependent: :destroy,
             inverse_of: :questionnaire
    has_many :info_slides,
             foreign_key: "vignettes_questionnaire_id",
             dependent: :destroy,
             inverse_of: :questionnaire
    has_many :user_answers,
             foreign_key: "vignettes_questionnaire_id",
             dependent: :destroy,
             inverse_of: :questionnaire

    has_rich_text :consent_text
    # Shown once the last slide is done. Unlike the consent text this stays
    # editable after publishing: nobody agreed to it, and a vignette that is
    # already running should not need a duplicate just to say thank you.
    has_rich_text :closing_text

    validate :consent_text_for_data_collection

    def answers_data
      slides.includes(answers: [:options, :slide_statistic,
                                { user_answer: :codename }]).flat_map(&:answers)
    end

    def answer_data_csv
      Vignettes::CsvHandler.generate_questionnaire_csv(self)
    end

    def last_slide
      return nil if slides.empty?

      slides.order(:position).last
    end

    # Nobody is asked to agree to nothing: a switch whose consent text went
    # missing does not collect, whatever the row says.
    def collecting?
      return false unless data_collection?
      return true if consent_text_present?

      Rails.logger.warn { "Vignette #{id}: data collection is on without a consent text" }
      false
    end

    # Trix leaves wrapper markup ("<div><br></div>") behind for an editor that
    # was emptied again, which a plain #present? would count as content.
    def consent_text_present?
      rich_text_present?(consent_text)
    end

    def closing_text_present?
      rich_text_present?(closing_text)
    end

    private

      def rich_text_present?(rich_text)
        rich_text.to_plain_text.strip.present?
      end

      def consent_text_for_data_collection
        return unless data_collection?
        return if consent_text_present?

        errors.add(:consent_text, :blank)
      end
  end
end
