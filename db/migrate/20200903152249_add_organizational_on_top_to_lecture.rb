class AddOrganizationalOnTopToLecture < ActiveRecord::Migration[6.0]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :lectures, :organizational_on_top, :boolean
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
