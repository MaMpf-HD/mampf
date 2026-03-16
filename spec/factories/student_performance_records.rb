FactoryBot.define do
  factory :student_performance_record,
          class: "StudentPerformance::Record" do
    association :lecture, factory: :lecture
    association :user, factory: :confirmed_user
    points_total_materialized { 0 }
    points_max_materialized { 100 }
    percentage_materialized { 0 }
    achievements_met_ids { [] }
    assessments_total_count { 0 }
    assessments_reviewed_count { 0 }
    assessments_pending_grading_count { 0 }
    assessments_not_submitted_count { 0 }
    assessments_exempt_count { 0 }
    computed_at { Time.current }
  end
end
