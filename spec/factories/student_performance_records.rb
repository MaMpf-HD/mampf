FactoryBot.define do
  factory :student_performance_record,
          class: "StudentPerformance::Record" do
    association :lecture, factory: :lecture
    association :user, factory: :confirmed_user
    points_total_materialized { 0 }
    points_max_materialized { 100 }
    percentage_materialized { 0 }
    achievements_met_ids { [] }
    computed_at { Time.current }
  end
end
