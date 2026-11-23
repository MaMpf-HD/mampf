# The MaMpf News page is gone.
# Announcements without a lecture don't notify anybody anymore, so the
# notifications for them can be deleted.
class DeleteMampfNewsNotifications < ActiveRecord::Migration[8.1]
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
