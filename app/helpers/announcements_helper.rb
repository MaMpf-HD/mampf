# Announcements Helper
module AnnouncementsHelper
  # Returns joined HTML of all admin-level announcements shown above the navbar.
  def site_announcements_html
    @site_announcements_html ||=
      Announcement.active_on_main.pluck(:details).join('<hr class="my-2">')
  end

  # create text for notification about new announcement in notification dropdown
  # menu
  def announcement_notification_item_header(announcement)
    return t("notifications.mampf_announcement") if announcement.lecture.blank?

    t("notifications.lecture_announcement",
      title: announcement.lecture.title_for_viewers)
  end

  # make announcements cards colored if the announcement is active
  def news_card_color(announcement)
    return "" unless user_signed_in?
    return "bg-post-it-blue" if announcement.active?(current_user)

    ""
  end

  # create text for lecture announcement in notification card header
  def announcement_notification_card_header(announcement)
    link_to(announcement.lecture.title_for_viewers,
            announcement.lecture.path(current_user),
            class: "text-dark")
  end
end
