class AddOnMainPageToAnnouncement < ActiveRecord::Migration[6.0]
  def up
    add_column :announcements, :on_main_page, :boolean, default: false
  end

  def down
    remove_column :announcements, :on_main_page, :boolean
  end
end
