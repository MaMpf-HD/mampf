class AddPropagateToLectureToCohorts < ActiveRecord::Migration[8.0]
  def change
    add_column :cohorts, :propagate_to_lecture, :boolean, default: false, null: false
  end
end
