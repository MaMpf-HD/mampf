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
    text = 'Neues Medium in ' + medium.teachable.media_scope.title_for_viewers
  end

  def medium_notification_item_details(medium)
    medium.local_title_for_viewers
  end

  # create text for notification about new medium in notification card
  def medium_notification_card_header(medium)
    link_to(medium.teachable.media_scope.title_for_viewers,
            polymorphic_path(medium.teachable.media_scope),
            class: 'text-dark')
  end

  # create link to medium in notification card
  def medium_notification_card_link(medium)
    link_to(medium.local_title_for_viewers,
            medium,
            class: 'darkblue')
  end
end
