class AddTermIndependentToCourse < ActiveRecord::Migration[6.0]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :courses, :term_independent, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
