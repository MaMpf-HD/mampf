FactoryBot.define do
  factory :lecture do
    association :course
    association :teacher
    association :term
    content_mode { 'video' }
    sort { 'lecture' }

    trait :with_organizational_stuff do
      organizational { true }
      organizational_concept { Faker::ChuckNorris.fact }
    end

    trait :released do
      released { true }
    end
  end
end
