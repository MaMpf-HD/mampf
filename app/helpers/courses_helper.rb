module CoursesHelper
  # create text for notification about new course in notification dropdown menu
  def course_notification(course)
    text = 'Neues Modul ' +
             course.title +
             tag(:br) +
             'Über Deine Profileinstellungen' +
             tag(:br) +
             'kannst Du es abonnieren.'
    text.html_safe
  end
end
