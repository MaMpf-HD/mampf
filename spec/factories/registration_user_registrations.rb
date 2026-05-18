FactoryBot.define do
  factory :registration_user_registration,
          class: "Registration::UserRegistration" do
    association :user, factory: :confirmed_user
    registration_campaign { association :registration_campaign }
    registration_item do
      association :registration_item, registration_campaign: registration_campaign
    end
    status { :pending }
    preference_rank { nil }

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
                  factory: [:registration_campaign, :first_come_first_served]
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
