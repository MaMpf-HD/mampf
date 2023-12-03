# rubocop:disable Rails/
class AddTitleAndPositionToTalk < ActiveRecord::Migration[6.1]
  def up
    add_column :talks, :title, :text
    add_column :talks, :position, :integer
  end

  def down
    remove_column :talks, :title, :text
    remove_column :talks, :position, :integer
  end
end
# rubocop:enable Rails/
