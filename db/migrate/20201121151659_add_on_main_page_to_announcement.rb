class AddOnMainPageToAnnouncement < ActiveRecord::Migration[6.0]
  def up
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :announcements, :on_main_page, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end

  def down
    remove_column :announcements, :on_main_page, :boolean
  end
end
