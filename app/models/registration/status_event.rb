module Registration
  class StatusEvent < ApplicationRecord
    self.table_name = "registration_status_events"

    ACTIONS = [
      "system_confirm",
      "system_reject",
      "teacher_reject",
      "teacher_reinstate"
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
