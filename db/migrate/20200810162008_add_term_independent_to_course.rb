class AddTermIndependentToCourse < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :term_independent, :boolean, default: false
  end
end
