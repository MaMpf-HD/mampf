# The MaMpf News page is gone. Announcements without a lecture now only feed
# the banner on the main page and stay listed in the admin panel, but nobody
# gets notified about them anymore, so their notifications have no place left.
class DeleteMampfNewsNotifications < ActiveRecord::Migration[8.0]
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
  end

  def down
    raise(ActiveRecord::IrreversibleMigration)
  end
end
