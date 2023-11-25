class AddOrganizationalDataToCourse < ActiveRecord::Migration[5.2]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :courses, :organizational, :boolean # rubocop:todo Rails/BulkChangeTable, Rails/ThreeStateBooleanColumn
    # rubocop:enable Rails/ThreeStateBooleanColumn
    add_column :courses, :organizational_concept, :text
  end
end
