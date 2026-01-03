FactoryBot.define do
  factory :speaker_talk_join do
    association :speaker, factory: :user
    association :talk
    source_campaign { nil }
  end
end
