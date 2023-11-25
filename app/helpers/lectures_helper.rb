# Lectures Helper
module LecturesHelper
  # is the current user allowed to delete the given lecture and is it
  # irrelevant enough to be able to do so?
  def lecture_deletable?(lecture)
    lecture.lessons.empty? && lecture.media.empty? &&
      (current_user.admin? ||
        lecture.editors_with_inheritance.include?(current_user))
  end

  # create text for notification about new lecture in notification dropdown menu
  def lecture_notification_item_header(lecture)
    t("notifications.new_lecture", title: lecture.title_for_viewers)
  end

  # create text for notification card
  def lecture_notification_item_details(_lecture)
    t("notifications.subscribe_lecture")
  end

  # create text for notification about new course in notification card
  def lecture_notification_card_text(lecture)
    t("notifications.new_lecture_created_html",
      title: lecture.course.title,
      term: lecture.term_to_label,
      teacher: lecture.teacher.name)
  end

  # create link for notification about new course in notification card
  def lecture_notification_card_link
    t("notifications.subscribe_lecture_html",
      profile: link_to(t("notifications.profile"),
                       edit_profile_path,
                       class: "darkblue"))
  end

  def days_short
    ["Mo", "Di", "Mi", "Do", "Fr"]
  end

  # unpublished lecture get a different link color
  def lectures_color(lecture)
    return "" if lecture.published?

    "unpublished"
  end

  # hidden chapters get a different color
  def chapter_card_color(chapter)
    return "bg-mdb-color-lighten-5" unless chapter.hidden

    "greyed_out bg-grey"
  end

  # hidden chapters get a different header color
  def chapter_header_color(chapter)
    return "bg-mdb-color-lighten-2" unless chapter.hidden

    ""
  end

  # hidden sections get a different color
  def section_color(section)
    return "" unless section.hidden

    "greyed_out"
  end

  # hidden sections get a different background color
  def section_background_color(section)
    return "bg-mdb-color-lighten-6" unless !section.chapter.hidden && section.hidden

    "bg-grey"
  end

  def news_color(news_count)
    return "" unless news_count.positive?

    "text-primary"
  end

  def lecture_header_color(subscribed, lecture)
    return "" unless subscribed

    result = "text-light "
    result += if lecture.term
      "bg-mdb-color-lighten-1"
    else
      "bg-info"
    end
  end

  def circle_icon(subscribed)
    return "fas fa-check-circle" if subscribed

    "far fa-circle"
  end

  def lecture_border(lecture)
    return "" if lecture.published?

    "border-danger"
  end

  def lecture_access_icon(lecture)
    return lecture_edit_icon if current_user.can_edit?(lecture)

    lecture_view_icon
  end

  def lecture_edit_icon(lecture)
    link_to edit_lecture_path(lecture),
            class: "text-dark me-2",
            style: "text-decoration: none;",
            data: { toggle: "tooltip",
                    placement: "bottom" },
            title: t("buttons.edit") do
      tag.i class: "far fa-edit"
    end
  end

  def lecture_view_icon(lecture)
    link_to lecture_path(lecture),
            class: "text-dark me-2",
            style: "text-decoration: none;",
            data: { toggle: "tooltip",
                    placement: "bottom" },
            title: t("buttons.view") do
      tag.i class: "fas fa-eye"
    end
  end
end
