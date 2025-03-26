class AddVisibleToVignettesQuestionnaires < ActiveRecord::Migration[7.1]
  def change
    add_column :vignettes_questionnaires, :editable, :boolean, default: true
  end
end
