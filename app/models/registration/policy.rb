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

    scope :referencing_campaign, lambda { |campaign_id|
      where("config->>'prerequisite_campaign_id' = ?", campaign_id.to_s)
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
      handler.summary || "-"
    end

    delegate :evaluate, to: :handler

    def handler
      return Registration::Policy::Handler.new(self) if kind.blank?

      @handler ||= case kind.to_sym
                   when :institutional_email
                     Registration::Policy::InstitutionalEmailHandler.new(self)
                   when :prerequisite_campaign
                     Registration::Policy::PrerequisiteCampaignHandler.new(self)
                   when :student_performance
                     Registration::Policy::Handler.new(self)
                   else
                     raise(ArgumentError, "Unknown policy kind: #{kind}")
      end
    end

    scope :referencing_campaign, lambda { |campaign_id|
      where("config->>'prerequisite_campaign_id' = ?", campaign_id.to_s)
    }

    private

      def campaign_is_draft
        return unless registration_campaign && !registration_campaign.draft?

        errors.add(:base, :frozen)
      end

      def validate_config
        handler.validate
      end

      def ensure_campaign_is_draft
        return unless registration_campaign && !registration_campaign.draft?

        errors.add(:base, :frozen)
        throw(:abort)
      end
  end
end
