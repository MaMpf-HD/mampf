FactoryBot.define do
  factory :registration_policy, class: "Registration::Policy" do
    association :registration_campaign
    kind { :institutional_email }
    phase { :registration }

    trait :institutional_email do
      kind { :institutional_email }
    end

    trait :student_performance do
      kind { :student_performance }
    end

    trait :prerequisite_campaign do
      kind { :prerequisite_campaign }
    end

    trait :for_finalization do
      phase { :finalization }
    end

    trait :for_both_phases do
      phase { :both }
    end
  end
end
