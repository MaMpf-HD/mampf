# Notification class
class Notification < ApplicationRecord
  # included for polymorphic_url method
  include ActionDispatch::Routing::PolymorphicRoutes
  include Rails.application.routes.url_helpers

  belongs_to :recipient, class_name: "User", touch: true
  belongs_to :notifiable, polymorphic: true, optional: true

  paginates_per 12

  # returns the lecture associated to a notification of type announcement,
  # and teachable for a notification of type medium, nil otherwise
  def teachable
    return if notifiable.blank?
    return if lecture_or_course?
    return notifiable.lecture if announcement_or_redemption?

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

    if redemption?
      edit_lecture_path(notifiable.voucher.lecture, anchor: "people")
    elsif lecture_or_course?
      edit_profile_path
    elsif lecture_announcement?
      notifiable.lecture.path(user)
    elsif generic_announcement?
      news_path
    elsif quiz?
      medium_path(notifiable)
    else
      polymorphic_url(notifiable, only_path: true)
    end
  end

  # the next methods are for the determination which kind of notification it is

  def medium?
    notifiable.is_a?(Medium)
  end

  def course?
    notifiable.is_a?(Course)
  end

  def lecture?
    notifiable.is_a?(Lecture)
  end

  def redemption?
    notifiable.is_a?(Redemption)
  end

  def announcement?
    notifiable.is_a?(Announcement)
  end

  def generic_announcement?
    announcement? && notifiable.lecture.nil?
  end

  def lecture_announcement?
    announcement? && notifiable.lecture.present?
  end

  def quiz?
    medium? && notifiable.sort == "Quiz"
  end

  private

    def lecture_or_course?
      notifiable_type.in?(["Lecture", "Course"])
    end

    def announcement_or_redemption?
      notifiable_type.in?(["Announcement", "Redemption"])
    end
end
