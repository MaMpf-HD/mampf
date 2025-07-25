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
    "#{medium.title}.mp4"
  end

  def manuscript_download_file(medium)
    "#{medium.title}.pdf"
  end

  def geogebra_download_file(medium)
    "#{medium.title}.ggb"
  end

  def inspect_or_edit_medium_path(medium, inspection)
    inspection ? inspect_medium_path(medium) : edit_medium_path(medium)
  end

  # create text for notification about new medium in notification dropdown menu
  def medium_notification_item_header(medium)
    return unless medium.proper?

    t("notifications.new_medium_in") + medium.scoped_teachable_title
  end

  def medium_notification_item_details(medium)
    medium.local_title_for_viewers
  end

  # create text for notification about new medium in notification card
  def medium_notification_card_header(medium)
    teachable = medium.teachable
    return teachable.media_scope.title_for_viewers if teachable.media_scope.instance_of?(::Course)

    link_to(teachable.media_scope.title_for_viewers,
            medium.teachable.media_scope.path(current_user),
            class: "text-dark")
  end

  # create link to medium in notification card
  def medium_notification_card_link(medium)
    link_to(medium.local_title_for_viewers,
            medium.becomes(Medium),
            class: "darkblue")
  end

  def section_selection(medium)
    medium.teachable&.lecture&.section_selection
  end

  def preselected_sections(medium)
    return [] unless medium.teachable.instance_of?(::Lesson)

    medium.teachable.sections.map(&:id)
  end

  def textcolor(medium)
    return "" if medium.visible?
    return "locked" if medium.locked?
    return "scheduled_release" if medium.publisher.present?

    "unpublished"
  end

  def infotainment(medium)
    return "nichts" unless medium.video || medium.manuscript
    return "ein Video" unless medium.manuscript
    return "ein Manuskript" unless medium.video

    "ein Video und ein Manuskript"
  end

  def level_to_word(medium)
    return t("basics.not_set") if medium.level.blank?
    return t("basics.level_easy") if medium.level.zero?
    return t("basics.level_medium") if medium.level == 1

    t("basics.level_hard")
  end

  def independent_to_word(medium)
    return t("basics.no_lc") unless medium.independent

    t("basics.yes_lc")
  end

  def medium_border(medium)
    return if medium.published? && !medium.locked?

    "border-danger"
  end

  def media_sorts_select(purpose)
    return add_prompt(Medium.select_quizzables) if purpose == "quiz"
    return add_prompt(Medium.select_importables) if purpose == "import"
    return add_prompt(Medium.select_generic) unless current_user.admin_or_editor?

    add_prompt(Medium.select_sorts)
  end

  def sort_preselect(purpose)
    return "" unless purpose == "quiz"

    "Question"
  end

  def related_media_hash(references, media)
    media_list = references.map { |r| [r.medium, r.manuscript_link] } +
                 media.zip(Array.new(media.size))
    hash = {}
    Medium.sort_enum.each do |s|
      media_in_s = media_list.select { |m| m.first.sort == s }
      hash[s] = media_in_s if media_in_s.present?
    end
    hash
  end

  def release_date_info(medium)
    return if medium.publisher.blank?

    t("admin.medium.scheduled_for_release_short",
      release_date: I18n.l(medium.publisher&.release_date,
                           format: :long,
                           locale: I18n.locale))
  end

  def edit_or_show_medium_path(medium)
    return edit_medium_path(medium) if current_user.can_edit?(medium)

    medium_path(medium)
  end

  def external_link_description_not_empty(medium)
    # Uses link display name if not empty, otherwise falls back to the
    # link url itself.
    medium.external_link_description.presence || medium.external_reference_link
  end

  def video_link_timed(medium, timestamp)
    Rails.application.routes.url_helpers
         .play_medium_path(medium, params: { time: timestamp.total_seconds })
  end

  def feedback_video_link_timed(medium, timestamp)
    feedback_medium_path(medium, params: { time: timestamp.total_seconds })
  end
end
