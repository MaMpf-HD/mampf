FactoryBot.define do
  factory :lesson_tag_join do
    association :lesson
    association :tag
  end
end
