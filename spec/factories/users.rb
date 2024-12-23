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
      after(:build, &:skip_confirmation_notification!)
    end

    trait :auto_confirmed do
      after(:create, &:confirm)
    end

    trait :with_confirmation_sent_date do
      transient do
        confirmation_sent_date { Time.zone.now }
      end

      after(:create) do |user, context|
        user.update(confirmation_sent_at: context.confirmation_sent_date)
      end
    end

    trait :consented do
      after(:create) do |user|
        user.update(consents: true, consented_at: Time.zone.now)
      end
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
                                      :auto_confirmed,
                                      :consented]

    factory :confirmed_user_en, traits: [:skip_confirmation_notification,
                                         :auto_confirmed,
                                         :consented] do
      locale { "en" }
    end
  end
end
