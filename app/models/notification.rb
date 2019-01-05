# Notification class
class Notification < ApplicationRecord
  # included for polymorphic_url method
  include ActionDispatch::Routing::PolymorphicRoutes
  include Rails.application.routes.url_helpers

  belongs_to :recipient, class_name: 'User'

  paginates_per 12

  # retrieve notifiable defined by notifiable_type and notifiable_id
  def notifiable
    return unless notifiable_type.in?(Notification.allowed_notifiable_types) &&
                  notifiable_id.present?
    notifiable_type.constantize.find_by_id(notifiable_id)
  end

  # returns the path that the user is sent to when the notification is clicked:
  # profile path for notifications about new courses or lectures
  # lecture path for announcements in lectures
  # news path for general announcements
  # all other cases: notifiable path
  def path(user)
    return unless notifiable.present?
    return edit_profile_path if notifiable_type.in?(['Course', 'Lecture'])
    if notifiable_type == 'Announcement'
      return notifiable.lecture.path(user) if notifiable.lecture.present?
      return news_path
    end
    polymorphic_url(notifiable, only_path: true)
  end

  def self.allowed_notifiable_types
    ['Medium', 'Course', 'Lecture', 'Announcement']
  end

  # the next methods are for the determination which kind of notification it is

  def medium?
    return unless notifiable.present?
    notifiable.class.to_s == 'Medium'
  end

  def course?
    return unless notifiable.present?
    notifiable.class.to_s == 'Course'
  end

  def lecture?
    return unless notifiable.present?
    notifiable.class.to_s == 'Lecture'
  end

  def announcement?
    return unless notifiable.present?
    notifiable.class.to_s == 'Announcement'
  end

  def sesam?
    medium? && notifiable.sort == 'Sesam'
  end

  def nuesse?
    medium? && notifiable.sort == 'Nuesse'
  end

  def quiz?
    medium? && notifiable.sort == 'KeksQuiz'
  end

  def generic_announcement?
    announcement? && notifiable.lecture.nil?
  end

  def lecture_announcement?
    announcement? && notifiable.lecture.present?
  end
end
