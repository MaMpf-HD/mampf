# Notification class
class Notification < ApplicationRecord
  include ActionDispatch::Routing::PolymorphicRoutes
  include Rails.application.routes.url_helpers
  belongs_to :recipient, class_name: 'User'
  paginates_per 10

  def notifiable
    return unless notifiable_type.in?(['Medium']) && notifiable_id.present?
    notifiable_type.constantize.find_by_id(notifiable_id)
  end

  def path
    return unless notifiable.present?
    polymorphic_url(notifiable, only_path: true)
  end


  def self.allowed_notifiable_types
    ['Medium']
  end
end
