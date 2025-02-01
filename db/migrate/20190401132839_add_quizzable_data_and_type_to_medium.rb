class AddQuizzableDataAndTypeToMedium < ActiveRecord::Migration[5.2]
  def change
    add_column :media, :hint, :text
    add_column :media, :parent_id, :integer
    add_column :media, :quiz_graph, :text
    add_column :media, :level, :integer
    add_column :media, :type, :text
  end
end
