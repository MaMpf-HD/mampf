require 'faker'

FactoryBot.define do
  factory :course do
    title { Faker::Book.title + ' ' +
            Faker::Number.between(from: 1, to: 999).to_s }
    short_title { Faker::Book.title + ' ' +
                  Faker::Number.between(from: 1, to: 999).to_s }

    trait :term_independent do
      term_independent { true }
    end

    trait :with_organizational_stuff do
      organizational { true }
      organizational_concept { Faker::ChuckNorris.fact }
    end

    trait :locale_de do
      locale { 'de'}
    end

    trait :with_tags do
      after(:build) do |course|
        course.tags = FactoryBot.create_list(:tag, 3)
      end
    end
  end
end
