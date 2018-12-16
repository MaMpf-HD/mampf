# Notifications Helper
module NotificationsHelper
  def menu_item(notification)
    notifiable = notification.notifiable
    return unless notifiable.class.to_s == 'Medium'
    date_tag = content_tag(:div,
                human_readable_date(notification.created_at),
                class: 'text-right smaller-font smaller-font')
    return date_tag +
             'Neues Medium in ' +
             notifiable.teachable.media_scope.title_for_viewers +
             tag(:br) +
             notifiable.local_title_for_viewers
  end
end