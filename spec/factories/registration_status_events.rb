FactoryBot.define do
  factory :registration_status_event, class: "Registration::StatusEvent" do
    association :registration, factory: :registration_user_registration
    registration_campaign { registration.registration_campaign }
    action { "teacher_reject" }
    reason_type { "manual" }
    reason_code { "withdrawn_by_teacher" }
    actor { nil }
    correlation_id { SecureRandom.uuid }
    schema_version { 1 }
    snapshot { { "label" => "Teacher rejected" } }

    trait :system_confirm do
      action { "system_confirm" }
      reason_type { nil }
      reason_code { nil }
      snapshot { { "label" => "Confirmed" } }
    end

    trait :system_reject do
      action { "system_reject" }
      reason_type { "capacity" }
      reason_code { "solver_unassigned" }
      snapshot { { "label" => "Not placed by solver" } }
    end

    trait :teacher_reinstate do
      action { "teacher_reinstate" }
      reason_type { "manual" }
      reason_code { "reinstated_by_teacher" }
      snapshot { { "label" => "Reinstated by teacher" } }
    end
  end
end
