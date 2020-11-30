require 'faker'

FactoryBot.define do
  factory :course do
    title { Faker::Book.title + ' ' +
            Faker::Number.between(from: 1, to: 999).to_s }
    short_title { Faker::Book.title + ' ' +
                  Faker::Number.between(from: 1, to: 999).to_s }
    locale { ['de', 'en'].sample }
    organizational { [true, false].sample }
    organizational_concept { Faker::ChuckNorris.fact }
    term_independent {false}
    trait :with_tags do
      after(:build) do |course|
        course.tags = FactoryBot.create_list(:tag, 3)
      end
    end
  end
end
