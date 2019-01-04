# Announcements Helper
module AnnouncementsHelper
  # create text for notification about new announcement in notification dropdown
  # menu
  def announcement_notification_header(announcement)
    text = 'Neue Mitteilung '
    if announcement.lecture.present?
      return text + 'in ' + announcement.lecture.title_for_viewers
    end
    text + ' über MaMpf'
  end

  # make announcements cards colored if the announcement is active
  def news_card_color(announcement)
    return '' unless user_signed_in?
    return 'bg-post-it-blue' if announcement.active?(current_user)
    ''
  end
end
