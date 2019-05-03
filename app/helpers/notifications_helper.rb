# Notifications Helper
module NotificationsHelper
  # create text for notification in notification dropdown menu
  def notification_menu_item_header(notification)
    notifiable = notification.notifiable
    return '' unless notifiable
    return medium_notification_item_header(notifiable) if notification.medium?
    return course_notification_item_header(notifiable) if notification.course?
    return lecture_notification_item_header(notifiable) if notification.lecture?
    announcement_notification_item_header(notifiable)
  end

  # create text for notification details in notification dropdown menu
  def notification_menu_item_details(notification)
    notifiable = notification.notifiable
    return medium_notification_item_details(notifiable) if notification.medium?
    return course_notification_item_details(notifiable) if notification.course?
    if notification.lecture?
      return lecture_notification_item_details(notifiable)
    end
    ''
  end

  # determine the color of a notification card
  def notification_color(notification)
    return 'bg-post-it-blue' if notification.generic_announcement?
    return 'bg-post-it-red' if notification.announcement?
    return 'bg-post-it-orange' if notification.course? || notification.lecture?
    'bg-post-it-yellow'
  end

  # provide text or link for header of notification card
  def notification_header(notification)
    notifiable = notification.notifiable
    text = if notification.medium?
             medium_notification_card_header(notifiable)
           elsif notification.course? || notification.lecture?
             t('notifications.course_selection')
           elsif notification.lecture_announcement?
             announcement_notification_card_header(notifiable)
           else
             link_to t('mampf_news.title'), news_path, class: 'text-dark'
           end
    text.html_safe
  end

  # provide text for body of notification card
  def notification_text(notification)
    notifiable = notification.notifiable
    text = if notification.medium?
             t('notifications.new_medium')
           elsif notification.course?
             course_notification_card_text(notifiable)
           elsif notification.lecture?
             lecture_notification_card_text(notifiable)
           else
             t('notifications.new_announcement')
           end
    text.html_safe
  end

  # provide link for body of notification card
  def notification_link(notification)
    notifiable = notification.notifiable
    return '' unless notifiable
    text = if notification.medium?
             medium_notification_card_link(notifiable)
           elsif notification.course?
             course_notification_card_link
           elsif notification.lecture?
             lecture_notification_card_link
           else
             notifiable.details
           end
    text.html_safe
  end
end
