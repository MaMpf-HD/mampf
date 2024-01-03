FactoryBot.define do
  factory :link do
    association :medium
    association :linked_medium, factory: :medium
  end
end
