# Announcement class
class Announcement < ApplicationRecord
  belongs_to :lecture, optional: true
  belongs_to :announcer, class_name: 'User'

	validates :details,
            presence: { message: 'Details müssen vorhanden sein.' }
end
