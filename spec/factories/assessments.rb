FactoryBot.define do
  factory :assessment, class: "Assessment::Assessment" do
    association :assessable, factory: [:assignment, :with_lecture]
    lecture { assessable.lecture }
    requires_points { false }
    requires_submission { false }

    trait :with_points do
      requires_points { true }
    end

    trait :with_submission do
      requires_submission { true }
    end

    trait :published do
      results_published_at { 1.day.ago }
    end

    trait :with_tasks do
      with_points
      after(:create) do |assessment|
        create_list(:assessment_task, 3, assessment: assessment)
      end
    end

    trait :with_participations do
      after(:create) do |assessment|
        create_list(:assessment_participation, 3, assessment: assessment)
      end
    end
  end
end
