# Lectures Helper
module LecturesHelper
  # returns true if it is an inspection AND the current user has editing rights
  # to the lecture (beig editor by inheritance or admin)
  def inspection_and_editor?(inspection, lecture)
    inspection &&
      (current_user.admin || current_user.in?(lecture.editors_with_inheritance))
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
    t('notifications.new_lecture', title: lecture.title_for_viewers)
  end

  # create text for notification card
  def lecture_notification_item_details(lecture)
    t('notifications.subscribe_lecture')
  end

  # create text for notification about new course in notification card
  def lecture_notification_card_text(lecture)
    t('notifications.new_lecture_created_html',
      title: lecture.course.title,
      term: lecture.term.to_label,
      teacher: lecture.teacher.name)
  end

  # create link for notification about new course in notification card
  def lecture_notification_card_link
    t('notifications.subscribe_lecture_html',
      profile: link_to(t('notifications.profile'),
                       edit_profile_path,
                       class: 'darkblue'))
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
    return "(#{lecture.sort_localized_short}) #{term}" unless lecture.primary?(user)
    ('&starf; (' + lecture.sort_localized_short + ') ' + term).html_safe
  end

  def days_short
    ['Mo', 'Di', 'Mi', 'Do', 'Fr']
  end

  # unpublished lecture get a different link color
  def lectures_color(lecture)
    return '' if lecture.published?
    'unpublished'
  end

  # hidden chapters get a different color
  def chapter_card_color(chapter)
    return 'bg-mdb-color-lighten-5' unless chapter.hidden
    'greyed_out bg-grey'
  end

  # hidden chapters get a different header color
  def chapter_header_color(chapter)
    return 'bg-mdb-color-lighten-2' unless chapter.hidden
    ''
  end

  # hidden sections get a different color
  def section_color(section)
    return '' unless section.hidden
    'greyed_out'
  end

  # hidden sections get a different background color
  def section_background_color(section)
    unless !section.chapter.hidden && section.hidden
      return 'bg-mdb-color-lighten-6'
    end
    'bg-grey'
  end
end
