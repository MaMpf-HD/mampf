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
    validate :campaign_is_draft, on: [:create, :update]
    validate :validate_config

    before_destroy :ensure_campaign_is_draft

    acts_as_list scope: :registration_campaign

    scope :active, -> { where(active: true) }

    scope :for_phase, lambda { |phase|
      where(phase: [phases[:both], phases[phase]])
    }

    # Virtual attributes for form handling and validation
    def allowed_domains
      val = config&.fetch("allowed_domains", nil)
      return val if val.is_a?(String)

      Array(val).join(", ")
    end

    def allowed_domains=(value)
      self.config ||= {}
      self.config["allowed_domains"] = value
    end

    def prerequisite_campaign_id
      config&.fetch("prerequisite_campaign_id", nil)
    end

    def prerequisite_campaign_id=(value)
      self.config ||= {}
      self.config["prerequisite_campaign_id"] = value
    end

    def config_summary
      case kind.to_sym
      when :institutional_email
        val = allowed_domains
        val.is_a?(Array) ? val.join(", ") : val.to_s
      when :prerequisite_campaign
        Registration::Campaign.find_by(id: prerequisite_campaign_id)&.title
      else
        return "-" if config.blank?

        config.to_json
      end
    end

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
        raw_domains = config&.fetch("allowed_domains", nil)
        # Handle comma-separated string from form or array from JSON
        domains = if raw_domains.is_a?(String)
          raw_domains.split(",")
        else
          Array(raw_domains)
        end

        domains = domains.map { |d| (d || "").strip.downcase }.reject(&:empty?)

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

      def validate_config
        case kind.to_sym
        when :institutional_email
          validate_institutional_email_config
        when :prerequisite_campaign
          validate_prerequisite_campaign_config
        end
      end

      def validate_institutional_email_config
        raw_domains = config&.fetch("allowed_domains", nil)
        # Handle comma-separated string from form or array from JSON
        domains = if raw_domains.is_a?(String)
          raw_domains.split(",")
        else
          Array(raw_domains)
        end

        return unless domains.map(&:strip).reject(&:empty?).empty?

        errors.add(:allowed_domains, I18n.t("registration.policy.errors.missing_domains"))
      end

      def validate_prerequisite_campaign_config
        campaign_id = config&.fetch("prerequisite_campaign_id", nil)
        if campaign_id.blank?
          errors.add(:prerequisite_campaign_id,
                     I18n.t("registration.policy.errors.missing_prerequisite_campaign"))
        elsif !Registration::Campaign.exists?(campaign_id)
          errors.add(:prerequisite_campaign_id,
                     I18n.t("registration.policy.errors.prerequisite_campaign_not_found"))
        end
      end

      def ensure_campaign_is_draft
        return unless registration_campaign && !registration_campaign.draft?

        errors.add(:base, :frozen)
        throw(:abort)
      end
  end
end
