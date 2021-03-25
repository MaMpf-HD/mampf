class AddPublisherToMedium < ActiveRecord::Migration[6.0]
  def up
    add_column :media, :publisher, :text
  end

  def down
    remove_column :media, :publisher, :text
  end
end
