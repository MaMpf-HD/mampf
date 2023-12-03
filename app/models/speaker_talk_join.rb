class SpeakerTalkJoin < ApplicationRecord
  belongs_to :talk
  belongs_to :speaker, class_name: "User", inverse_of: :speaker_talk_join
end
