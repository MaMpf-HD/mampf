class AddVignettesQuestionnaireToInfoSlide < ActiveRecord::Migration[7.1]
  def change
    add_reference :vignettes_info_slides, :vignettes_questionnaire, index: true
  end
end
