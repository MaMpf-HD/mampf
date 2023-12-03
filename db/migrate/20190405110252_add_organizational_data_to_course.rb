class AddOrganizationalDataToCourse < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :organizational, :boolean
    add_column :courses, :organizational_concept, :text
  end
end
