FactoryBot.define do
  factory :link do
    association :medium
    association :linked_medium
  end
end
