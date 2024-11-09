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
    result + if lecture.term
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
    link_to(edit_lecture_path(lecture),
            class: "text-dark me-2",
            style: "text-decoration: none;",
            data: { toggle: "tooltip",
                    placement: "bottom" },
            title: t("buttons.edit")) do
      tag.i(class: "far fa-edit")
    end
  end

  def lecture_view_icon(lecture)
    link_to(lecture_path(lecture),
            class: "text-dark me-2",
            style: "text-decoration: none;",
            data: { toggle: "tooltip",
                    placement: "bottom" },
            title: t("buttons.view")) do
      tag.i(class: "fas fa-eye")
    end
  end

  def editors_preselection(lecture)
    options_for_select(lecture.eligible_as_editors.map do |editor|
                         [editor.info, editor.id]
                       end, lecture.editor_ids)
  end

  def teacher_select(form, is_new_lecture, lecture = nil)
    if current_user.admin?
      label = form.label(:teacher_id, t("basics.teacher"), class: "form-label")
      help_desk = helpdesk(t("admin.lecture.info.teacher"), false)

      preselection = if is_new_lecture
        options_for_select([[current_user.info, current_user.id]], current_user.id)
      else
        options_for_select([[lecture.teacher.info, lecture.teacher.id]], lecture.teacher.id)
      end

      # TODO: Rubocop bug when trying to break the last object on a new line
      select = form.select(:teacher_id, preselection, {}, { class: "selectize",
                                                            multiple: true,
                                                            data: {
                                                              ajax: true,
                                                              filled: false,
                                                              model: "user",
                                                              placeholder: t("basics.enter_two_letters"), # rubocop:disable Layout/LineLength
                                                              no_results: t("basics.no_results"),
                                                              modal: true,
                                                              cy: "teacher-admin-select"
                                                            } })

      error_div = content_tag(:div, "", class: "invalid-feedback", id: "lecture-teacher-error")

      return label + help_desk + select + error_div
    end

    # Non-admin cases
    if is_new_lecture
      p1 = content_tag(:p) do
        concat(t("basics.teacher"))
        concat(helpdesk(t("admin.lecture.info.teacher_fixed_new_lecture"), false))
      end
      p2 = content_tag(:p, current_user.info)

    else
      p1 = content_tag(:p) do
        concat(t("basics.teacher"))
        concat(helpdesk(t("admin.lecture.info.teacher_fixed"), false))
      end
      p2 = content_tag(:p, lecture.teacher.info, "data-cy": "teacher-info")
    end

    p1 + p2
  end

  def editors_select(form, lecture)
    if current_user.admin?
      preselection = options_for_select(lecture.select_editors, lecture.editors.map(&:id))
      form.select(:editor_ids, preselection, {}, {
                    class: "selectize",
                    multiple: true,
                    data: {
                      ajax: true,
                      filled: false,
                      model: "user",
                      placeholder: t("basics.enter_two_letters"),
                      no_results: t("basics.no_results"),
                      modal: true
                    }
                  })
    else
      form.select(:editor_ids, editors_preselection(lecture), {},
                  class: "selectize",
                  multiple: true,
                  "data-cy": "lecture-editors-select")
    end
  end
end
