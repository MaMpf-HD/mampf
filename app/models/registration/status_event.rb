module Registration
  class StatusEvent < ApplicationRecord
    self.table_name = "registration_status_events"

    ACTION_SYSTEM_CONFIRM = "system_confirm".freeze
    ACTION_SYSTEM_REJECT = "system_reject".freeze
    ACTION_TEACHER_REJECT = "teacher_reject".freeze
    ACTION_TEACHER_REINSTATE = "teacher_reinstate".freeze

    REASON_TYPE_CAPACITY = "capacity".freeze
    REASON_TYPE_MANUAL = "manual".freeze

    REASON_CODE_SOLVER_UNASSIGNED = "solver_unassigned".freeze
    REASON_CODE_WITHDRAWN_BY_TEACHER = "withdrawn_by_teacher".freeze
    REASON_CODE_REINSTATED_BY_TEACHER = "reinstated_by_teacher".freeze

    ACTIONS = [
      ACTION_SYSTEM_CONFIRM,
      ACTION_SYSTEM_REJECT,
      ACTION_TEACHER_REJECT,
      ACTION_TEACHER_REINSTATE
    ].freeze

    REASON_TYPES = [
      REASON_TYPE_CAPACITY,
      REASON_TYPE_MANUAL
    ].freeze

    belongs_to :registration,
               class_name: "Registration::UserRegistration",
               inverse_of: :status_events

    belongs_to :registration_campaign,
               class_name: "Registration::Campaign",
               inverse_of: :status_events

    belongs_to :actor,
               class_name: "User",
               optional: true

    validates :action,
              presence: true,
              inclusion: { in: ACTIONS }
    validates :schema_version, presence: true
    validates :schema_version,
              numericality: { only_integer: true, greater_than: 0 }

    validate :snapshot_must_be_a_hash
    validate :registration_campaign_must_match_registration

    private

      def snapshot_must_be_a_hash
        return if snapshot.is_a?(Hash)

        errors.add(:snapshot, :invalid)
      end

      def registration_campaign_must_match_registration
        return unless registration && registration_campaign_id
        return if registration.registration_campaign_id == registration_campaign_id

        errors.add(:registration_campaign, :invalid)
      end
  end
end
