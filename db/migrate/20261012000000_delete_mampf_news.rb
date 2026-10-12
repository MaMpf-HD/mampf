# The MaMpf News page is gone. Announcements without a lecture now only feed
# the banner on the main page, so the ones not shown there have no place left,
# and neither do the notifications about any of them.
class DeleteMampfNews < ActiveRecord::Migration[8.0]
  # Minimal models, so the migration does not depend on the app's models.
  class Announcement < ApplicationRecord
    self.table_name = "announcements"
  end

  class Notification < ApplicationRecord
    self.table_name = "notifications"
  end

  def up
    news = Announcement.where(lecture_id: nil)
    Notification.where(notifiable_type: "Announcement", notifiable_id: news.select(:id))
                .delete_all
    news.where(on_main_page: [false, nil]).delete_all
  end

  def down
    raise(ActiveRecord::IrreversibleMigration)
  end
end
