class AddFileLastEdited < ActiveRecord::Migration[6.1]
  def up
    add_column :media, :file_last_edited, :datetime, default: nil
  end

  def down
    remove_column :media, :file_last_edited, :datetime
  end
end
