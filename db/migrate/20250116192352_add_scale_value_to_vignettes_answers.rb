class AddScaleValueToVignettesAnswers < ActiveRecord::Migration[7.1]
  def change
    add_column :vignettes_answers, :scale_value, :integer
  end
end
