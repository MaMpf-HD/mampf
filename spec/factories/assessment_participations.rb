FactoryBot.define do
  factory :assessment_participation, class: "Assessment::Participation" do
    association :assessment
    association :user, factory: :confirmed_user
    tutorial { nil }
    grader { nil }
    points_total { nil }
    grade_numeric { nil }
    grade_text { nil }
    status { :pending }
    submitted_at { nil }
    graded_at { nil }
    results_published_at { nil }
    published { false }
    locked { false }

    trait :with_tutorial do
      association :tutorial
    end

    trait :pending do
      status { :pending }
      submitted_at { nil }
    end

    trait :submitted do
      status { :pending }
      submitted_at { 1.day.ago }
    end

    trait :reviewed do
      association :assessment, factory: [:assessment, :for_expired_assignment]
      status { :reviewed }
      submitted_at { 2.days.ago }
      graded_at { 1.day.ago }
      points_total { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    end

    # A sheet that has come back from the tutor: a value on every task and the
    # participation closed. The tasks have to exist before the status turns,
    # because a new task reopens every reviewed participation of its assessment.
    trait :marked do
      association :assessment,
                  factory: [:assessment, :for_expired_assignment, :with_points]
      status { :pending }
      submitted_at { 2.days.ago }

      transient do
        max_points_per_task { [4, 4] }
        points_per_task { [1.5, 2] }
      end

      after(:create) do |participation, evaluator|
        tasks = evaluator.max_points_per_task.map do |max_points|
          create(:assessment_task, assessment: participation.assessment,
                                   max_points: max_points)
        end
        tasks.each_with_index do |task, index|
          create(:assessment_task_point,
                 task: task,
                 assessment_participation: participation,
                 points: evaluator.points_per_task[index])
        end
        participation.reload.update!(status: :reviewed, graded_at: 1.day.ago)
      end
    end

    trait :absent do
      status { :absent }
      submitted_at { nil }
    end

    trait :exempt do
      status { :exempt }
      submitted_at { nil }
    end

    trait :with_numeric_grade do
      reviewed
      association :assessment, factory: [:assessment, :gradable]
      grade_numeric { [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0].sample }
    end

    trait :with_text_grade do
      reviewed
      association :assessment, factory: [:assessment, :gradable]
      grade_text { ["pass", "fail"].sample }
    end

    trait :published do
      reviewed
      published { true }
      results_published_at { 1.hour.ago }
    end

    trait :locked do
      published
      locked { true }
    end
  end
end
