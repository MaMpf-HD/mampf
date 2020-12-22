# frozen_string_literal: true

FactoryBot.define do
  factory :user, aliases: [:teacher] do
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    name { Faker::Name.name }
    locale { I18n.available_locales.map(&:to_s).sample }

    transient do
      lecture_count { 2 }
    end

    trait :skip_confirmation_notification do
      after(:build)  { |user| user.skip_confirmation_notification! }
    end

    trait :auto_confirmed do
      after(:create) { |user| user.confirm }
    end


    # call it with build(:user, :with_lectures, lecture_count: n) if you want
    # n subscribed lectures associated to the user
    trait :with_lectures do
      after(:build) do |user, evaluator|
        user.lectures = FactoryBot.create_list(:lecture,
                                               evaluator.lecture_count)
      end
    end

    factory :confirmed_user, traits: [:skip_confirmation_notification,
                                      :auto_confirmed]
  end
end
