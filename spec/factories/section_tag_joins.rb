FactoryBot.define do
  factory :section_tag_join do
    association :tag
    association :section
  end
end
