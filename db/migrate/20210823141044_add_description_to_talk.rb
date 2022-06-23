class AddDescriptionToTalk < ActiveRecord::Migration[6.1]
  def up
    add_column :talks, :description, :text
  end

  def down
    remove_column :talks, :description, :text
  end
end
