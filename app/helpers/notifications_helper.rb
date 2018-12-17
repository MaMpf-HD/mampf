# Notifications Helper
module NotificationsHelper
  def notification_menu_item(notification)
    notifiable = notification.notifiable
    return unless notifiable.class.to_s
                            .in?(Notification.allowed_notifiable_types)
    date_tag = content_tag(:div, human_readable_date(notification.created_at),
                           class: 'text-right smaller-font')
    text = date_tag +
             if notifiable.class.to_s == 'Medium'
               medium_notification(notifiable)
             elsif notifiable.class.to_s == 'Course'
               course_notification(notifiable)
             else
               lecture_notification(notifiable)
             end
    text.html_safe
  end

  def notification_text(notification)
    notifiable = notification.notifiable
    return unless notifiable.class.to_s
                            .in?(Notification.allowed_notifiable_types)
    text = if notifiable.class.to_s == 'Medium'
             'Neues Medium in ' +
                link_to(notifiable.teachable.media_scope.title_for_viewers,
                        polymorphic_path(notifiable.teachable.media_scope),
                        class: 'text-dark')
           elsif notifiable.class.to_s == 'Course'
             'Neues Modul ' + notifiable.title
           else
             'Neue Vorlesung ' + notifiable.title_for_viewers
           end
    text.html_safe
  end

  def notification_link(notification)
    notifiable = notification.notifiable
    if notifiable.class.to_s == 'Medium'
      return link_to(notifiable.local_title_for_viewers, notifiable)
    else
      return link_to('Profileinstellungen', edit_profile_path)
    end
  end
end
