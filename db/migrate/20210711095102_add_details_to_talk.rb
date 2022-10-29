class AddDetailsToTalk < ActiveRecord::Migration[6.1]
  def up
    add_column :talks, :details, :text
  end

  def down
    remove_column :talks, :details, :text
  end
end
