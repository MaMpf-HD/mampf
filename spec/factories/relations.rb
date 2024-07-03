FactoryBot.define do
  factory :relation do
    association :tag
    association :related_tag
  end
end
