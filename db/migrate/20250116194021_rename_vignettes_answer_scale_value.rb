class RenameVignettesAnswerScaleValue < ActiveRecord::Migration[7.1]
  def change
    rename_column :vignettes_answers, :scale_value, :likert_scale_value
  end
end
