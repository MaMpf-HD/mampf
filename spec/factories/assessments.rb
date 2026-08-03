FactoryBot.define do
  factory :assessment, class: "Assessment::Assessment" do
    association :assessable, factory: [:assignment, :with_lecture]
    lecture { assessable.lecture }

    # An assessable creates its own gradebook while the flag is on, and there is
    # only ever one per assessable, so the factory takes that one over.
    initialize_with do
      # Queried rather than read off the association: `assessable.assessment`
      # would cache its result on the object the example holds, and a cached
      # nil survives the assessment this factory is about to create.
      existing = assessable.persisted? &&
                 Assessment::Assessment.find_by(
                   assessable_type: assessable.class.name,
                   assessable_id: assessable.id
                 )

      existing || Assessment::Assessment.new(assessable: assessable)
    end
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

    trait :gradable do
      association :assessable, factory: :talk
      lecture { assessable.lecture }
    end

    trait :for_expired_assignment do
      association :assessable, factory: [:assignment, :expired, :with_lecture]
      lecture { assessable.lecture }
    end

    trait :for_exam do
      association :assessable, factory: :exam
      lecture { assessable.lecture }
    end
  end
end
