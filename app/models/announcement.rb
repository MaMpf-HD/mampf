# Announcement class
class Announcement < ApplicationRecord
  belongs_to :lecture, optional: true
  belongs_to :announcer, class_name: 'User'

	validates :details,
            presence: { message: 'Es muss ein Text vorhanden sein.' }

  paginates_per 10

  def active?(user)
  	user.notifications.where(notifiable_type: 'Announcement',
														 notifiable_id: id).present?
  end
end
