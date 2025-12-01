module Registration
  # Represents a rule or constraint that a user must satisfy to register.
  # Acts as a gatekeeper (e.g. "Must have passed Exam X") that can be applied
  # at different phases (registration or finalization).
  class Policy < ApplicationRecord
    belongs_to :registration_campaign,
               class_name: "Registration::Campaign",
               inverse_of: :registration_policies

    enum :kind, { institutional_email: 0,
                  prerequisite_campaign: 1,
                  student_performance: 2 }

    enum :phase, { registration: 0,
                   finalization: 1,
                   both: 2 }

    validates :kind, :phase, presence: true
    validates :active, inclusion: { in: [true, false] }
    validates :position, uniqueness: { scope: :registration_campaign_id }

    acts_as_list scope: :registration_campaign

    scope :active, -> { where(active: true) }

    scope :for_phase, lambda { |phase|
      where(phase: [phases[:both], phases[phase]])
    }

    validate :campaign_is_draft, on: [:create, :update]
    before_destroy :ensure_campaign_is_draft

    def evaluate(user)
      case kind.to_sym
      when :institutional_email
        evaluate_institutional_email(user)
      when :prerequisite_campaign
        evaluate_prerequisite_campaign(user)
      else
        raise(ArgumentError, "Unknown policy kind: #{kind}")
      end
    end

    private

      def pass_result(code = :ok, details = {})
        { pass: true, code: code, details: details }
      end

      def fail_result(code, message, details = {})
        { pass: false, code: code, message: message, details: details }
      end

      def evaluate_institutional_email(user)
        domains = Array(config&.fetch("allowed_domains", nil)).map do |domain|
          (domain || "").strip.downcase
        end.reject(&:empty?)

        return fail_result(:configuration_error, "No allowed domains configured") if domains.empty?

        email = user.email.to_s.downcase
        allowed = domains.any? do |domain|
          email.end_with?("@#{domain}")
        end

        if allowed
          pass_result(:domain_ok)
        else
          fail_result(:institutional_email_mismatch, "Email domain not allowed",
                      allowed_domains: domains)
        end
      end

      def evaluate_prerequisite_campaign(user)
        campaign_id = config&.fetch("prerequisite_campaign_id", nil)

        if campaign_id.blank?
          return fail_result(:configuration_error,
                             "Prerequisite campaign not configured")
        end

        prereq_campaign = Registration::Campaign.find_by(id: campaign_id)

        unless prereq_campaign
          return fail_result(:prerequisite_campaign_not_found,
                             "Prerequisite campaign missing")
        end

        if prereq_campaign.user_registration_confirmed?(user)
          pass_result(:prerequisite_met)
        else
          fail_result(:prerequisite_not_met,
                      "Prerequisite campaign not completed")
        end
      end

      def campaign_is_draft
        return unless registration_campaign && !registration_campaign.draft?

        errors.add(:base, :frozen)
      end

      def ensure_campaign_is_draft
        return unless registration_campaign && !registration_campaign.draft?

        errors.add(:base, :frozen)
        throw(:abort)
      end
  end
end
