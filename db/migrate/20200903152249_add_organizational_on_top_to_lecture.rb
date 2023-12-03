class AddOrganizationalOnTopToLecture < ActiveRecord::Migration[6.0]
  def change
    add_column :lectures, :organizational_on_top, :boolean
  end
end
