FactoryBot.define do
  factory :student_performance_certification,
          class: "StudentPerformance::Certification" do
    association :lecture, factory: :lecture
    association :user, factory: :confirmed_user
    status { :pending }
    source { :computed }

    trait :pending do
      status { :pending }
      certified_by { nil }
      certified_at { nil }
    end

    trait :passed do
      status { :passed }
      association :certified_by, factory: :confirmed_user
      certified_at { Time.current }
    end

    trait :failed do
      status { :failed }
      association :certified_by, factory: :confirmed_user
      certified_at { Time.current }
    end

    trait :manual do
      source { :manual }
      note { "Manual override" }
    end
  end
end
