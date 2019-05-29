class AddTagIdToNotion < ActiveRecord::Migration[6.0]
  def change
    add_column :notions, :tag_id, :integer
    add_index :notions, :tag_id
  end
end
