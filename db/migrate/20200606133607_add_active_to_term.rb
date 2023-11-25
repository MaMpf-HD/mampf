class AddActiveToTerm < ActiveRecord::Migration[6.0]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :terms, :active, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
