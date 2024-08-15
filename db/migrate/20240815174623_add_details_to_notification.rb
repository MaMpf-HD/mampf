class AddDetailsToNotification < ActiveRecord::Migration[7.1]
  def change
    add_column :notifications, :details, :text
  end
end
