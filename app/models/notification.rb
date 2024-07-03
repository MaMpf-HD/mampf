# Notification class
class Notification < ApplicationRecord
  # included for polymorphic_url method
  include ActionDispatch::Routing::PolymorphicRoutes
  include Rails.application.routes.url_helpers

  belongs_to :recipient, class_name: "User", touch: true
  belongs_to :notifiable, polymorphic: true, optional: true

  paginates_per 12

  # retrieve notifiable defined by notifiable_type and notifiable_id
  #  def notifiable
  #    return unless notifiable_type.in?(Notification.allowed_notifiable_types) &&
  #                  notifiable_id.present?
  #    notifiable_type.constantize.find_by_id(notifiable_id)
  #  end

  # returns the lecture associated to a notification of type announcement,
  # and teachable for a notification of type medium, nil otherwise
  def teachable
    return if notifiable.blank?
    return if notifiable_type.in?(["Lecture", "Course"])
    return notifiable.lecture if notifiable_type == "Announcement"

    # notifiable will be a medium, so return its teachable
    notifiable.teachable
  end

  # returns the path that the user is sent to when the notification is clicked:
  # profile path for notifications about new courses or lectures
  # lecture path for announcements in lectures
  # news path for general announcements
  # all other cases: notifiable path
  def path(user)
    return if notifiable.blank?
    return edit_profile_path if notifiable_type.in?(["Course", "Lecture"])

    if notifiable_type == "Announcement"
      return notifiable.lecture.path(user) if notifiable.lecture.present?

      return news_path
    end
    return medium_path(notifiable) if notifiable_type == "Medium" && notifiable.sort == "Quiz"

    polymorphic_url(notifiable, only_path: true)
  end

  def self.allowed_notifiable_types
    ["Medium", "Course", "Lecture", "Announcement"]
  end

  # the next methods are for the determination which kind of notification it is

  def medium?
    return false if notifiable.blank?

    notifiable_type == "Medium"
  end

  def course?
    return false if notifiable.blank?

    notifiable.instance_of?(::Course)
  end

  def lecture?
    return false if notifiable.blank?

    notifiable.instance_of?(::Lecture)
  end

  def announcement?
    return false if notifiable.blank?

    notifiable.instance_of?(::Announcement)
  end

  def generic_announcement?
    announcement? && notifiable.lecture.nil?
  end

  def lecture_announcement?
    announcement? && notifiable.lecture.present?
  end
end
