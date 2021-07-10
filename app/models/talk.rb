class Talk < ApplicationRecord
  belongs_to :lecture
  has_many :speaker_talk_joins, dependent: :destroy
  has_many :speakers, through: :speaker_talk_joins
end
