FactoryBot.define do
  factory :registration_user_registration,
          class: "Registration::UserRegistration" do
    association :user, factory: :confirmed_user
    association :registration_campaign
    association :registration_item
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
      # transient do
      #   registration_campaign_override { nil }
      #   registration_item_override { nil }
      # end

      association :registration_campaign,
                  factory: [:registration_campaign, :first_come_first_served]

      # after(:build) do |registration, evaluator|
      #   if evaluator.registration_campaign_override
      #     registration.registration_campaign = evaluator.registration_campaign_override
      #   end
      #   if evaluator.registration_item_override
      #     registration.registration_item = evaluator.registration_item_override
      #   end
      # end

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
