class AddOrganizationalToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :organizational, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
