class CreateEditableUserJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_table :editable_user_joins do |t|
      t.integer :editable_id
      t.string  :editable_type
      t.integer :user_id
     end
     add_index :editable_user_joins, [:editable_id, :editable_type, :user_id], :name => 'polymorphic_many_to_many_idx'
     add_index :editable_user_joins, [:editable_id, :editable_type], :name => 'polymorphic_editable_idx'
  end
end
