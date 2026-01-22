FactoryBot.define do
  factory :assessment, class: "Assessment::Assessment" do
    association :assessable, factory: [:assignment, :with_lecture]
    lecture { assessable.lecture }
    title { "#{Faker::Educator.course_name} Assessment" }
    requires_points { false }
    requires_submission { false }
    status { :draft }

    trait :with_points do
      requires_points { true }
    end

    trait :with_submission do
      requires_submission { true }
    end

    trait :open do
      status { :open }
      visible_from { 1.day.ago }
    end

    trait :closed do
      status { :closed }
      due_at { 1.day.ago }
    end

    trait :graded do
      status { :graded }
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
