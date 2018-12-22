module CoursesHelper
  # create text for notification about new course in notification dropdown menu
  def course_notification_header(course)
    text = 'Neues Modul' + course.title
  end

  def course_notification_details(course)
  	'Über Deine Profileinstellungen kannst Du es abonnieren.'
  end
end
