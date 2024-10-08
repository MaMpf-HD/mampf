# Announcement class
class Announcement < ApplicationRecord
  # changing an announcement needs to make the lecture cache key expire
  belongs_to :lecture, optional: true, touch: true
  belongs_to :announcer, class_name: "User"

  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :details, presence: true

  paginates_per 10

  scope :active_on_main, -> { where(on_main_page: true, lecture: nil) }

  # does there (still) exist a notification for the announcement for
  # the given user
  def active?(user)
    user.notifications.exists?(notifiable: self)
  end
end
