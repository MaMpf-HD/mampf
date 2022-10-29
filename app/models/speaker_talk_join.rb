class SpeakerTalkJoin < ApplicationRecord
  belongs_to :talk
  belongs_to :speaker, class_name: 'User', foreign_key: 'speaker_id'
end
