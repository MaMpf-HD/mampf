class AddTitleAndPositionToTalk < ActiveRecord::Migration[6.1]
  def up
    add_column :talks, :title, :text # rubocop:todo Rails/BulkChangeTable
    add_column :talks, :position, :integer
  end

  def down
    remove_column :talks, :title, :text # rubocop:todo Rails/BulkChangeTable
    remove_column :talks, :position, :integer
  end
end
