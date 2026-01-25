FactoryBot.define do
  factory :assessment_participation, class: "Assessment::Participation" do
    association :assessment
    association :user, factory: :confirmed_user
    tutorial { nil }
    grader { nil }
    points_total { nil }
    grade_numeric { nil }
    grade_text { nil }
    status { :not_started }
    submitted_at { nil }
    graded_at { nil }
    results_published_at { nil }
    published { false }
    locked { false }

    trait :with_tutorial do
      association :tutorial
    end

    trait :submitted do
      status { :submitted }
      submitted_at { 1.day.ago }
    end

    trait :graded do
      status { :graded }
      submitted_at { 2.days.ago }
      graded_at { 1.day.ago }
      points_total { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    end

    trait :with_numeric_grade do
      graded
      grade_numeric { [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0].sample }
    end

    trait :with_text_grade do
      graded
      grade_text { ["pass", "fail"].sample }
    end

    trait :published do
      graded
      published { true }
      results_published_at { 1.hour.ago }
    end

    trait :locked do
      published
      locked { true }
    end
  end
end
