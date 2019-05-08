# Media Helper
module MediaHelper
  # returns the array of all teachables, together with a string made up
  # from their class and id
  # Is used in options_for_select in form helpers.
  def all_teachables_selection(user)
    Course.editable_selection(user) + Lecture.editable_selection(user) +
      Lesson.editable_selection(user)
  end

  # does the current user have the right to edit the given medium?
  def medium_editor?(medium)
    current_user.admin || medium.edited_with_inheritance_by?(current_user)
  end

  def video_download_file(medium)
    medium.title + '.mp4'
  end

  def manuscript_download_file(medium)
    medium.title + '.pdf'
  end

  def inspect_or_edit_medium_path(medium, inspection)
    inspection ? inspect_medium_path(medium) : edit_medium_path(medium)
  end

  # create text for notification about new medium in notification dropdown menu
  def medium_notification_item_header(medium)
    return unless medium.proper?
    t('notifications.new_medium_in') + medium.teachable.media_scope.title_for_viewers
  end

  def medium_notification_item_details(medium)
    medium.local_title_for_viewers
  end

  # create text for notification about new medium in notification card
  def medium_notification_card_header(medium)
    teachable = medium.teachable
    if teachable.media_scope.class.to_s == 'Course'
      return link_to(teachable.media_scope.title_for_viewers,
                     course_path(medium.teachable.media_scope),
                     class: 'text-dark')
    end
    link_to(teachable.media_scope.title_for_viewers,
            medium.teachable.media_scope.path(current_user),
            class: 'text-dark')
  end

  # create link to medium in notification card
  def medium_notification_card_link(medium)
    link_to(medium.local_title_for_viewers,
            medium.becomes(Medium),
            class: 'darkblue')
  end

  def section_selection(medium)
    medium.teachable&.lecture&.section_selection
  end

  def preselected_sections(medium)
    return [] unless medium.teachable.class.to_s == 'Lesson'
    medium.teachable.sections.map(&:id)
  end


  def textcolor(medium)
    return '' if medium.visible?
    return 'locked' if medium.locked?
    'unpublished'
  end

  def infotainment(medium)
    return 'nichts' unless medium.video || medium.manuscript
    return 'ein Video' unless medium.manuscript
    return 'ein Manuskript' unless medium.video
    'ein Video und ein Manuskript'
  end

  def level_to_word(medium)
    return t('quiz.level.not_set') unless medium.level.present?
    return t('quiz.level.easy') if medium.level == 0
    return t('quiz.level.medium') if medium.level == 1
    t('quiz.level.difficult')
  end

  def independent_to_word(medium)
    return 'nein' unless medium.independent
    'ja'
  end
end
