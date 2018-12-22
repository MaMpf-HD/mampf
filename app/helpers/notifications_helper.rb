# Notifications Helper
module NotificationsHelper
  def notification_menu_item_header(notification)
    notifiable = notification.notifiable
    if notifiable.class.to_s == 'Medium'
      medium_notification_header(notifiable)
    elsif notifiable.class.to_s == 'Course'
      course_notification_header(notifiable)
    else
      lecture_notification_header(notifiable)
    end
  end

  def notification_menu_item_details(notification)
    notifiable = notification.notifiable
    if notifiable.class.to_s == 'Medium'
      medium_notification_details(notifiable)
    elsif notifiable.class.to_s == 'Course'
      course_notification_details(notifiable)
    else
      lecture_notification_details(notifiable)
    end
  end

  def notification_header(notification)
    notifiable = notification.notifiable
    return unless notifiable.class.to_s
                            .in?(Notification.allowed_notifiable_types)
    text = if notifiable.class.to_s == 'Medium'
             link_to(notifiable.teachable.media_scope.title_for_viewers,
                     polymorphic_path(notifiable.teachable.media_scope),
                     class: 'text-dark')
           else
             'Kursangebot'
           end
    text.html_safe
  end

  def notification_color(notification)
    notifiable = notification.notifiable
    if notifiable.class.to_s == 'Medium' && notifiable.sort == 'Sesam'
      return 'bg-post-it-green'
    elsif notifiable.class.to_s == 'Medium' && notifiable.sort == 'Nuesse'
      return 'bg-post-it-pink'
    elsif notifiable.class.to_s == 'Medium' && notifiable.sort == 'KeksQuiz'
      return 'bg-post-it-blue'
    elsif notifiable.class.to_s.in?(['Lecture', 'Course'])
      return 'bg-post-it-orange'
    end
    'bg-post-it-yellow'
  end

  def notification_text(notification)
    notifiable = notification.notifiable
    return unless notifiable.class.to_s
                            .in?(Notification.allowed_notifiable_types)
    text = if notifiable.class.to_s == 'Medium'
             'Neues Medium angelegt:'
           elsif notifiable.class.to_s == 'Course'
             'Neues Modul angelegt:' + tag(:br) + notifiable.course.title
           else
             'Neue Vorlesung angelegt:' + tag(:br) + notifiable.course.title +
             ' (' + notifiable.term.to_label + ', ' +
             notifiable.teacher.name + ')'
           end
    text.html_safe
  end

  def notification_link(notification)
    notifiable = notification.notifiable
    if notifiable.class.to_s == 'Medium'
      return link_to(notifiable.local_title_for_viewers, notifiable,
                     style: 'color:  #2251dd;')
    else
      return ('Du kannst sie über Deine ' +
               link_to('Profileinstellungen', edit_profile_path,
                       style: 'color:  #2251dd;') +
               ' abonnieren.').html_safe
    end
  end
end
