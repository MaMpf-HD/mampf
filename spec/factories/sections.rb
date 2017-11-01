FactoryBot.define do
  factory :section do
    association :chapter
    number { Faker::Number.between(1, 999) }
    title { Faker::Book.title + ' ' + Random.rand(1..99).to_s }
    trait :with_lessons do
      after(:create) { |s| s.lessons = s.lecture.lessons.sample(2) }
    end
    trait :with_tags do
      after(:create) { |s| s.tags = s.lecture.tags.sample(2) }
    end
  end
end
