# Redemptions Helper
module RedemptionsHelper
  def redemption_notification_card_header(redemption)
    link_to(redemption.voucher.lecture.title_for_viewers,
            edit_lecture_path(redemption.voucher.lecture,
                              anchor: ("people" unless redemption.voucher.speaker?)),
            class: "text-dark")
  end

  def redemption_notification_item_header(redemption)
    t("notifications.redemption_in_lecture",
      lecture: redemption.voucher.lecture.title_for_viewers)
  end

  def redemption_notification_details(redemption)
    if redemption.voucher.tutor?
      tutor_notification_details(redemption)
    elsif redemption.voucher.editor?
      editor_notification_details(redemption)
    elsif redemption.voucher.teacher?
      teacher_notification_details(redemption)
    else
      speaker_notification_details(redemption)
    end
  end

  def redemption_notification_item_details(redemption)
    result = if redemption.voucher.tutor?
      tutor_notification_item_details(redemption)
    elsif redemption.voucher.editor?
      editor_notification_item_details(redemption)
    elsif redemption.voucher.teacher?
      teacher_notification_item_details(redemption)
    else
      speaker_notification_item_details(redemption)
    end

    truncate_result(result)
  end

  private

    def tutor_notification_item_details(redemption)
      tutorials = redemption.claimed_tutorials
      tutorial_details = tutorials.map(&:title).join(", ")

      base_message = "#{t("basics.tutor")} #{redemption.user.tutorial_name}"
      tutorials.any? ? "#{base_message}: #{tutorial_details}" : base_message
    end

    def editor_notification_item_details(redemption)
      "#{t("basics.editor")} #{redemption.user.tutorial_name}"
    end

    def teacher_notification_item_details(redemption)
      "#{t("basics.teacher")} #{redemption.user.tutorial_name}"
    end

    def speaker_notification_item_details(redemption)
      talks = redemption.claimed_talks
      talk_details = talks.map(&:to_label).join(", ")

      base_message = "#{t("basics.speaker")} #{redemption.user.tutorial_name}"
      talks.any? ? "#{base_message}: #{talk_details}" : base_message
    end

    def tutor_notification_details(redemption)
      user_info = I18n.t("notifications.became_tutor", user: redemption.user.info)
      tutorials = redemption.claimed_tutorials

      tutorial_details = if tutorials.present?
        I18n.t("notifications.tutorial_details",
               tutorials: tutorials.map(&:title).join(", "))
      else
        I18n.t("notifications.no_tutorials_taken")
      end

      user_info + tutorial_details
    end

    def editor_notification_details(redemption)
      I18n.t("notifications.became_editor", user: redemption.user.info)
    end

    def teacher_notification_details(redemption)
      I18n.t("notifications.became_teacher", user: redemption.user.info)
    end

    def speaker_notification_details(redemption)
      user_info = I18n.t("notifications.became_speaker", user: redemption.user.info)
      talks = redemption.claimed_talks

      talk_details = if talks.present?
        I18n.t("notifications.talk_details",
               talks: talks.map(&:to_label).join(", "))
      else
        I18n.t("notifications.no_talks_taken")
      end

      user_info + talk_details
    end
end
