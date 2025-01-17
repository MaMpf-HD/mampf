class AddTextToAnswers < ActiveRecord::Migration[7.1]
  def change
    add_column :vignettes_answers, :text, :text
  end
end
