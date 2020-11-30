FactoryBot.define do
  factory :lecture do
    association :course, factory: [:course, :with_tags]
    association :teacher
    association :term
  end
end
