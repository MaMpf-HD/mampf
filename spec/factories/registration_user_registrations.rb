FactoryBot.define do
  factory :registration_user_registration,
          class: "Registration::UserRegistration" do
    association :user, factory: :confirmed_user
    association :registration_campaign
    association :registration_item
    status { :pending }
    preference_rank { 1 }

    trait :pending do
      status { :pending }
    end

    trait :confirmed do
      status { :confirmed }
    end

    trait :rejected do
      status { :rejected }
    end

    trait :fcfs do
      association :registration_campaign,
                  factory: [:registration_campaign, :first_come_first_serve]
      preference_rank { nil }
      status { :confirmed }
    end

    trait :preference_based do
      association :registration_campaign,
                  factory: [:registration_campaign, :preference_based]
      preference_rank { 1 }
      status { :pending }
    end
  end
end
