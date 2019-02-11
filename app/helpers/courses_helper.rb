# Courses Helper
module CoursesHelper
  # create text for notification about new course in notification dropdown menu
  def course_notification_item_header(course)
    'Neues Modul ' + course.title
  end

  # create text for notification card
  def course_notification_item_details(course)
    'Über Deine Profileinstellungen kannst Du es abonnieren.'
  end

  # create text for notification about new course in notification card
  def course_notification_card_text(course)
    'Neues Modul angelegt:' + tag(:br) + course.title
  end

  # create link for notification about new lecture in notification card
  def course_notification_card_link
    'Du kannst es über Deine ' +
      link_to('Profileinstellungen', edit_profile_path,
              class: 'darkblue') +
      ' abonnieren.'
  end
end
