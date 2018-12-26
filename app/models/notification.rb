# Notification class
class Notification < ApplicationRecord
  include ActionDispatch::Routing::PolymorphicRoutes
  include Rails.application.routes.url_helpers
  belongs_to :recipient, class_name: 'User'
  paginates_per 12

  def notifiable
    return unless notifiable_type.in?(Notification.allowed_notifiable_types) &&
                  notifiable_id.present?
    notifiable_type.constantize.find_by_id(notifiable_id)
  end

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
    ['Medium','Course', 'Lecture', 'Announcement']
  end
end
