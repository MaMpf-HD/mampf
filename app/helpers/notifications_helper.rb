# Notifications Helper
module NotificationsHelper
  # create text for notification in notification dropdown menu
  def notification_menu_item_header(notification)
    notifiable = notification.notifiable
    return "" unless notifiable
    return medium_notification_item_header(notifiable) if notification.medium?
    return course_notification_item_header(notifiable) if notification.course?
    return lecture_notification_item_header(notifiable) if notification.lecture?
    return redemption_notification_item_header(notifiable) if notification.redemption?

    announcement_notification_item_header(notifiable)
  end

  # create text for notification details in notification dropdown menu
  def notification_menu_item_details(notification)
    notifiable = notification.notifiable
    return medium_notification_item_details(notifiable) if notification.medium?
    return course_notification_item_details(notifiable) if notification.course?
    return lecture_notification_item_details(notifiable) if notification.lecture?
    return redemption_notification_item_details(notifiable) if notification.redemption?

    ""
  end

  # determine the color of a notification card
  def notification_color(notification)
    return "bg-post-it-blue" if notification.generic_announcement?
    return "bg-post-it-red" if notification.announcement?
    return "bg-post-it-orange" if notification.course? || notification.lecture?
    return "bg-post-it-green" if notification.redemption?

    "bg-post-it-yellow"
  end

  # provide text or link for header of notification card
  def notification_header(notification)
    notifiable = notification.notifiable
    if notification.medium?
      medium_notification_card_header(notifiable)
    elsif notification.course? || notification.lecture?
      t("notifications.course_selection")
    elsif notification.lecture_announcement?
      announcement_notification_card_header(notifiable)
    elsif notification.redemption?
      redemption_notification_card_header(notifiable)
    else
      link_to(t("mampf_news.title"), news_path, class: "text-dark")
    end
  end

  # provide text for body of notification card
  def notification_text(notification)
    notifiable = notification.notifiable
    if notification.medium?
      t("notifications.new_medium")
    elsif notification.course?
      course_notification_card_text(notifiable)
    elsif notification.lecture?
      lecture_notification_card_text(notifiable)
    elsif notification.redemption?
      t("notifications.redemption")
    else
      t("notifications.new_announcement")
    end
  end

  # provide link for body of notification card
  def notification_link(notification)
    notifiable = notification.notifiable
    return "" unless notifiable

    if notification.medium?
      medium_notification_card_link(notifiable)
    elsif notification.course?
      course_notification_card_link
    elsif notification.lecture?
      lecture_notification_card_link
    elsif notification.redemption?
      redemption_notification_details(notifiable)
    else
      notifiable.details
    end
  end

  def items_card_size(small, comments_below)
    return "30vh" if comments_below
    return "60vh" if small

    "70vh"
  end

  # create text for lecture announcement in notification card header
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
      details = I18n.t("notifications.became_tutor", user: redemption.user.info)
      tutorial_titles = redemption.claimed_tutorials.map(&:title).join(", ")
      details << I18n.t("notifications.tutorial_details",
                        tutorials: tutorial_titles)
    else
      I18n.t("notifications.became_editor", user: redemption.user.info)
    end
  end

  def redemption_notification_item_details(redemption)
    result = if redemption.tutor?
      tutor_notification_item_details(redemption)
    elsif redemption.editor?
      editor_notification_item_details(redemption)
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

    def truncate_result(result)
      result.first(40).tap do |truncated|
        return truncated.length < 40 ? truncated : truncated + "..."
      end
    end
end
