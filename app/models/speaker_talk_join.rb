class SpeakerTalkJoin < ApplicationRecord
  belongs_to :talk
  belongs_to :speaker, class_name: "User" # rubocop:todo Rails/InverseOf
end
