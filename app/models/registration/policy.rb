module Registration
  class Policy < ApplicationRecord
    belongs_to :registration_campaign,
               class_name: "Registration::Campaign",
               inverse_of: :registration_policies

    enum :kind, { institutional_email: 0,
                  prerequisite_campaign: 1,
                  lecture_performance: 2 }

    enum :phase, { registration: 0,
                   finalization: 1,
                   both: 2 }

    validates :kind, :phase, presence: true
    validates :position, uniqueness: { scope: :registration_campaign_id }

    acts_as_list scope: :registration_campaign

    scope :active, -> { where(active: true) }

    scope :for_phase, lambda { |phase|
      where(phase: [phases[:both], phases[phase]])
    }

    def evaluate(user)
      case kind.to_sym
      when :institutional_email
        evaluate_institutional_email(user)
      when :prerequisite_campaign
        evaluate_prerequisite_campaign(user)
      else
        { pass: true, code: :ok }
      end
    end

    private

      def evaluate_institutional_email(user)
        domains = Array(config&.fetch("allowed_domains", nil)).map do |domain|
          (domain || "").strip.downcase
        end.reject(&:empty?)

        return { pass: true, code: :ok } if domains.empty?

        email = user.email.to_s.downcase
        allowed = domains.any? do |domain|
          email.end_with?("@#{domain}")
        end

        { pass: allowed, code: allowed ? :ok : :institutional_email_mismatch }
      end

      def evaluate_prerequisite_campaign(user)
        campaign_id = config&.fetch("prerequisite_campaign_id", nil)
        return { pass: true, code: :ok } if campaign_id.blank?

        prereq_campaign = Registration::Campaign.find_by(id: campaign_id)
        return { pass: false, code: :prerequisite_campaign_not_found } unless prereq_campaign

        registered = prereq_campaign.user_registered?(user)

        { pass: registered, code: registered ? :ok : :prerequisite_not_met }
      end
  end
end
