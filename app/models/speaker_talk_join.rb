# Represents a user's role as a speaker for a talk, tracking the source campaign
# to distinguish between automated allocations and manual assignments.
class SpeakerTalkJoin < ApplicationRecord
  belongs_to :talk
  belongs_to :speaker, class_name: "User", inverse_of: :speaker_talk_joins
  belongs_to :source_campaign, class_name: "Registration::Campaign", optional: true
end
