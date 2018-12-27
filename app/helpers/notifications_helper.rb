# Notifications Helper
module NotificationsHelper
  def notification_menu_item_header(notification)
    notifiable = notification.notifiable
    if notifiable.class.to_s == 'Medium'
      medium_notification_header(notifiable)
    elsif notifiable.class.to_s == 'Course'
      course_notification_header(notifiable)
    elsif notifiable.class.to_s == 'Lecture'
      lecture_notification_header(notifiable)
    else
      announcement_notification_header(notifiable)
    end
  end

  def notification_menu_item_details(notification)
    notifiable = notification.notifiable
    if notifiable.class.to_s == 'Medium'
      medium_notification_details(notifiable)
    elsif notifiable.class.to_s == 'Course'
      course_notification_details(notifiable)
    elsif notifiable.class.to_s == 'Lecture'
      lecture_notification_details(notifiable)
    else
      announcement_notification_details(notifiable)
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
           elsif notifiable.class.to_s.in?(['Course', 'Lecture'])
             'Kursangebot'
           else
             if notifiable.lecture.present?
               link_to(notifiable.lecture.title_for_viewers,
                       notifiable.lecture.path(current_user),
                       class: 'text-dark')
             else
              link_to 'MaMpf-News', news_path, class: 'text-dark'
             end
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
      return 'bg-post-it-light-green'
    elsif notifiable.class.to_s == 'Announcement' && notifiable.lecture.nil?
      return 'bg-post-it-blue'
    elsif notifiable.class.to_s == 'Announcement'
      return 'bg-post-it-red'
    elsif notifiable.class.to_s.in?(['Lecture', 'Course', 'Announcement'])
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
           elsif notifiable.class.to_s == 'Lecture'
             'Neue Vorlesung angelegt:' + tag(:br) + notifiable.course.title +
             ' (' + notifiable.term.to_label + ', ' +
             notifiable.teacher.name + ')'
           else
             'Neue Mitteilung:'
           end
    text.html_safe
  end

  def notification_link(notification)
    notifiable = notification.notifiable
    if notifiable.class.to_s == 'Medium'
      return link_to(notifiable.local_title_for_viewers, notifiable,
                     style: 'color:  #2251dd;')
    elsif notifiable.class.to_s.in?(['Lecture', 'Course'])
      return ('Du kannst sie über Deine ' +
               link_to('Profileinstellungen', edit_profile_path,
                       style: 'color:  #2251dd;') +
               ' abonnieren.').html_safe
    else
      notifiable.details
    end
  end

  def delete_notification_href(announcement, user)
    notification = user.matching_notification(announcement)
    return '' unless notification.present?
    'href=' + notification_path(notification)
  end
end
