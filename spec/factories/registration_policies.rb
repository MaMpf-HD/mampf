FactoryBot.define do
  factory :registration_policy, class: "Registration::Policy" do
    association :registration_campaign
    phase { :registration }
    institutional_email

    trait :institutional_email do
      kind { :institutional_email }
      config { { "allowed_domains" => "example.com" } }
    end

    trait :student_performance do
      kind { :student_performance }
    end

    trait :prerequisite_campaign do
      kind { :prerequisite_campaign }
      after(:build) do |policy|
        unless policy.config && policy.config["prerequisite_campaign_id"]
          prereq = create(:registration_campaign, :completed)
          policy.config ||= {}
          policy.config["prerequisite_campaign_id"] = prereq.id
        end
      end
    end

    trait :for_finalization do
      phase { :finalization }
    end

    trait :for_both_phases do
      phase { :both }
    end
  end
end
