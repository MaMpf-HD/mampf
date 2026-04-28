FactoryBot.define do
  factory :registration_status_event, class: "Registration::StatusEvent" do
    association :registration, factory: :registration_user_registration
    registration_campaign { registration.registration_campaign }
    action { Registration::StatusEvent::ACTION_TEACHER_REJECT }
    reason_type { Registration::StatusEvent::REASON_TYPE_MANUAL }
    reason_code { Registration::StatusEvent::REASON_CODE_WITHDRAWN_BY_TEACHER }
    actor { nil }
    correlation_id { SecureRandom.uuid }
    schema_version { 1 }
    snapshot { { "label" => "Teacher rejected" } }

    trait :system_confirm do
      action { Registration::StatusEvent::ACTION_SYSTEM_CONFIRM }
      reason_type { nil }
      reason_code { nil }
      snapshot { { "label" => "Confirmed" } }
    end

    trait :system_reject do
      action { Registration::StatusEvent::ACTION_SYSTEM_REJECT }
      reason_type { Registration::StatusEvent::REASON_TYPE_CAPACITY }
      reason_code { Registration::StatusEvent::REASON_CODE_SOLVER_UNASSIGNED }
      snapshot { { "label" => "Not placed by solver" } }
    end

    trait :teacher_reinstate do
      action { Registration::StatusEvent::ACTION_TEACHER_REINSTATE }
      reason_type { Registration::StatusEvent::REASON_TYPE_MANUAL }
      reason_code { Registration::StatusEvent::REASON_CODE_REINSTATED_BY_TEACHER }
      snapshot { { "label" => "Reinstated by teacher" } }
    end
  end
end
