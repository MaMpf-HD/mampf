class AddModulesToLecture < ActiveRecord::Migration[5.1]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :lectures, :kaviar, :boolean # rubocop:todo Rails/BulkChangeTable, Rails/ThreeStateBooleanColumn
    # rubocop:enable Rails/ThreeStateBooleanColumn
    add_column :lectures, :sesam, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :lectures, :keks, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :lectures, :reste, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :lectures, :erdbeere, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
