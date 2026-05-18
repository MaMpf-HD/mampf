class AddAliasedTagToNotion < ActiveRecord::Migration[6.0]
  def up
    add_column :notions, :aliased_tag_id, :integer
    add_index :notions, :aliased_tag_id
  end

  def down
    remove_column :notions, :aliased_tag_id
    remove_index :notions, :aliased_tag_id
  end
end
