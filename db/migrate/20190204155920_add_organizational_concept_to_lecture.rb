class AddOrganizationalConceptToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :organizational_concept, :text
  end
end
