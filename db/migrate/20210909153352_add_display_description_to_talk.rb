class AddDisplayDescriptionToTalk < ActiveRecord::Migration[6.1]
  def up
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :talks, :display_description, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end

  def down
    remove_column :talks, :display_description, :boolean
  end
end
