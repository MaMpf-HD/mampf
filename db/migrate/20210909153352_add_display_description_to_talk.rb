# rubocop:disable Rails/
class AddDisplayDescriptionToTalk < ActiveRecord::Migration[6.1]
  def up
    add_column :talks, :display_description, :boolean, default: false
  end

  def down
    remove_column :talks, :display_description, :boolean
  end
end
# rubocop:enable Rails/
