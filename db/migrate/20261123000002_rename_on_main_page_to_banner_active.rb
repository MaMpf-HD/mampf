# Announcements without a lecture are shown as a banner above the navbar
# (there is no main page listing them anymore). Only those can be active as a
# banner, so the database now enforces that for lecture announcements.
class RenameOnMainPageToBannerActive < ActiveRecord::Migration[8.1]
  # Minimal model, so the migration does not depend on the app's models.
  class Announcement < ApplicationRecord
    self.table_name = "announcements"
  end

  def up
    rename_column :announcements, :on_main_page, :banner_active
    Announcement.reset_column_information
    # admins could formerly set the flag on lecture announcements, too
    # rubocop:disable Rails/SkipsModelValidations
    Announcement.where.not(lecture_id: nil).update_all(banner_active: false)
    # rubocop:enable Rails/SkipsModelValidations
    change_column_null :announcements, :banner_active, false, false
    add_check_constraint :announcements, "lecture_id IS NULL OR NOT banner_active",
                         name: "banner_only_for_site_announcements"
  end

  def down
    remove_check_constraint :announcements, name: "banner_only_for_site_announcements"
    change_column_null :announcements, :banner_active, true
    rename_column :announcements, :banner_active, :on_main_page
  end
end
