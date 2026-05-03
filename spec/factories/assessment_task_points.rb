FactoryBot.define do
  factory :assessment_task_point, class: "Assessment::TaskPoint" do
    task { association(:assessment_task) }
    assessment_participation do
      association(:assessment_participation, assessment: task.assessment)
    end
    grader { nil }
    submission { nil }
    points { Faker::Number.decimal(l_digits: 1, r_digits: 2) }
    comment { nil }

    trait :with_grader do
      association :grader, factory: :confirmed_user
    end

    trait :with_submission do
      association :submission, factory: :valid_submission
    end

    trait :with_comment do
      comment { Faker::Lorem.sentence }
    end

    trait :full_points do
      points { task.max_points }
    end

    trait :zero_points do
      points { 0 }
    end

    trait :bonus_points do
      points { task.max_points + Faker::Number.between(from: 1, to: 5) }
    end
  end
end
