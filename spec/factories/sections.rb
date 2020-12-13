FactoryBot.define do
  factory :section do
    association :chapter
    title { Faker::Book.title + ' ' +
              Faker::Number.between(from: 1, to: 99).to_s }

  end
end
