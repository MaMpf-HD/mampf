module RegistrationCampaignContext
  private

    def apply_registration_context(registerable:, lecture:, error_target:)
      return true unless registration_section_campaign?

      campaign = find_or_create_registration_campaign(lecture: lecture,
                                                      error_target: error_target)
      return false unless campaign

      item = campaign.registration_items.build(registerable: registerable)
      unless RegistrationItemAbility.new(current_user).can?(:create, item)
        error_target.errors.add(:base, t("registration.campaign.create_failed"))
        return false
      end
      return true if item.save

      error_target.errors.add(:base, item.errors.full_messages.to_sentence)
      false
    end

    def find_or_create_registration_campaign(lecture:, error_target:)
      campaign = existing_registration_campaign(lecture: lecture,
                                                error_target: error_target)
      return campaign if campaign
      return nil if error_target.errors.any?

      campaign = lecture.registration_campaigns.build(
        description: t("registration.campaign.default_description"),
        allocation_mode: :first_come_first_served,
        registration_deadline: 2.weeks.from_now
      )
      unless RegistrationCampaignAbility.new(current_user).can?(:create, campaign)
        error_target.errors.add(:base, t("registration.campaign.create_failed"))
        return nil
      end
      return campaign if campaign.save

      error_target.errors.add(:base, campaign.errors.full_messages.to_sentence)
      nil
    end

    def existing_registration_campaign(lecture:, error_target:)
      campaign_id = params[:registration_campaign_id]
      scope = lecture.registration_campaigns.order(created_at: :desc)
      campaign = campaign_id.present? ? scope.find_by(id: campaign_id) : scope.first
      return campaign if campaign

      return nil if campaign_id.blank?

      error_target.errors.add(:base, t("registration.campaign.not_found"))
      nil
    end

    def registration_section_campaign?
      params[:registration_section].to_s == "campaign"
    end
end
