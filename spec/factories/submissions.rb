FactoryBot.define do
  factory :submission do
    transient do
      lecture { build(:lecture) }
    end

    trait :with_assignment do
      assignment { association :assignment, lecture: lecture }
    end

    trait :with_tutorial do
      tutorial { association :tutorial, lecture: lecture }
    end

    factory :valid_submission, traits: [:with_assignment, :with_tutorial]
  end
end
