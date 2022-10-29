class AddSolutionToMedium < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :solution, :text
  end
end
