# Lectures Helper
module LecturesHelper
  # returns true if it is an inspection AND the current user has editing rights
  # to the lecture (beig editor by inheritance or admin)
  def inspection_and_editor?(inspection, lecture)
    inspection &&
      (current_user.admin || current_user.in?(lecture.editors_with_inheritance))
  end

  # returns for a given lecture and inspection status
  # - the path for the inspect action for the lecture's course if
  #    (1) the user is no admin
  #    AND
  #    (2) it is an inspection and the user is no editor of the course
  # - the path for the edit action for the lecture's course in all other cases
  def inspect_or_edit_course_from_lecture(inspection, lecture)
    if (inspection || !lecture.course.editors.include?(current_user)) &&
       !current_user.admin?
      return inspect_course_path(lecture.course)
    end
    edit_course_path(lecture.course)
  end

  # is the current user allowed to delete the given lecture and is it
  # irrelevant enough to be able to do so?
  def lecture_deletable?(lecture, inspection)
    !inspection && lecture.lessons.empty? && lecture.media.empty? &&
      (current_user.admin? ||
        lecture.editors_with_inheritance.include?(current_user))
  end

  # create text for notification about new lecture in notification dropdown menu
  def lecture_notification_item_header(lecture)
    text = 'Neue Vorlesung ' + lecture.title_for_viewers
  end

  # create text for notification card
  def lecture_notification_item_details(lecture)
    'Über Deine Profileinstellungen kannst Du sie abonnieren.'
  end

  # create text for notification about new course in notification card
  def lecture_notification_card_text(lecture)
    'Neue Vorlesung angelegt:' + tag(:br) + lecture.course.title +
      ' (' + lecture.term.to_label + ', ' + lecture.teacher.name + ')'
  end

  # create link for notification about new course in notification card
  def lecture_notification_card_link
    'Du kannst sie über Deine ' +
      link_to('Profileinstellungen', edit_profile_path,
              class: 'darkblue') +
      ' abonnieren.'
  end

  # add a star to lecture's title if it is a user's primary lecture
  def starred_title(lecture, user)
    title = lecture.title_for_viewers
    return title unless lecture.primary?(user)
    ('&starf; ' + title).html_safe
  end

  # add a star to lecture's term if it is a user's primary lecture
  def starred_term(lecture, user)
    term = lecture.term.to_label_short
    return term unless lecture.primary?(user)
    ('&starf; ' + term).html_safe
  end

  def days_short
    ['Mo', 'Di', 'Mi', 'Do', 'Fr']
  end

  def lectures_color(lecture)
    return '' if lecture.released?
    'unreleased'
  end
end
