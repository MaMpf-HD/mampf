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

  def announcement_notification_details(announcement)
  	''
  end

  def active_announcement(announcement, user)
  	return '' unless announcement.active?(current_user)
  	'list-group-item-action list-group-item-info'
  end

  def news_card_color(announcement)
  	return '' unless user_signed_in?
  	return 'bg-post-it-blue' if announcement.active?(current_user)
  	''
  end
end
