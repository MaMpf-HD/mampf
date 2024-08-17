# Redemptions Helper
module RedemptionsHelper
  def redemption_notification_card_header(redemption)
    link_to(redemption.lecture.title_for_viewers,
            edit_lecture_path(redemption.lecture, anchor: "people"),
            class: "text-dark")
  end

  def redemption_notification_item_header(redemption)
    t("notifications.redemption_in_lecture",
      lecture: redemption.lecture.title_for_viewers)
  end

  def redemption_notification_details(redemption)
    if redemption.tutor?
      tutor_notification_details(redemption)
    elsif redemption.editor?
      editor_notification_details(redemption)
    elsif redemption.teacher?
      teacher_notification_details(redemption)
    end
  end

  def redemption_notification_item_details(redemption)
    result = if redemption.tutor?
      tutor_notification_item_details(redemption)
    elsif redemption.editor?
      editor_notification_item_details(redemption)
    elsif redemption.teacher?
      teacher_notification_item_details(redemption)
    end

    truncate_result(result)
  end

  private

    def tutor_notification_item_details(redemption)
      tutorials = redemption.claimed_tutorials.map(&:title).join(", ")
      "#{t("basics.tutor")} #{redemption.user.tutorial_name}: #{tutorials}"
    end

    def editor_notification_item_details(redemption)
      "#{t("basics.editor")} #{redemption.user.tutorial_name}"
    end

    def teacher_notification_item_details(redemption)
      "#{t("basics.teacher")} #{redemption.user.tutorial_name}"
    end

    def tutor_notification_details(redemption)
      details = I18n.t("notifications.became_tutor",
                       user: redemption.user.info)
      tutorial_titles = redemption.claimed_tutorials.map(&:title).join(", ")
      details << I18n.t("notifications.tutorial_details",
                        tutorials: tutorial_titles)
    end

    def editor_notification_details(redemption)
      I18n.t("notifications.became_editor", user: redemption.user.info)
    end

    def teacher_notification_details(redemption)
      I18n.t("notifications.became_teacher", user: redemption.user.info)
    end
end
