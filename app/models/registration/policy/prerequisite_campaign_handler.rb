module Registration
  class Policy
    # Handles the "Prerequisite Campaign" policy.
    # Checks if the user has a confirmed registration in a specific other campaign.
    class PrerequisiteCampaignHandler < Handler
      def evaluate(user)
        if campaign_id.blank?
          return fail_result(:configuration_error,
                             "Prerequisite campaign not configured")
        end
        unless campaign
          return fail_result(:prerequisite_campaign_not_found,
                             "Prerequisite campaign missing")
        end

        if campaign.user_registration_confirmed?(user)
          pass_result(:prerequisite_met)
        else
          fail_result(:prerequisite_not_met, "Prerequisite campaign not completed")
        end
      end

      def validate
        if campaign_id.blank?
          policy.errors.add(:prerequisite_campaign_id,
                            I18n.t("registration.policy.errors.missing_prerequisite_campaign"))
        elsif !Registration::Campaign.exists?(campaign_id)
          policy.errors.add(:prerequisite_campaign_id,
                            I18n.t("registration.policy.errors.prerequisite_campaign_not_found"))
        end
      end

      def summary
        campaign&.title
      end

      private

        def campaign_id
          config["prerequisite_campaign_id"]
        end

        def campaign
          return @campaign if defined?(@campaign)

          @campaign = Registration::Campaign.find_by(id: campaign_id)
        end
    end
  end
end
