module Registration
  class UserRegistration
    class Handler
      Result = Struct.new(:success?, :errors)

      def initialize(campaign, user, item = nil)
        @campaign = campaign
        @item = item
        @user = user
      end

      def check_campaign_open_for_registrations
        return nil if @campaign.open_for_registrations?

        I18n.t("registration.user_registration.messages.campaign_not_opened")
      end

      def check_campaign_open_for_withdraw
        return nil if @campaign.open_for_withdrawals?

        I18n.t("registration.user_registration.messages.campaign_not_opened")
      end

      def check_already_registered_current_type
        return nil unless @campaign.user_registration_confirmed_for_group_type?(@user,
                                                                                @item.registerable_type)

        I18n.t("registration.user_registration.messages.already_registered")
      end

      def check_capacity
        return nil if @item.still_has_capacity?

        I18n.t("registration.user_registration.messages.no_slots")
      end

      def check_policies
        return nil if [@campaign.policies_satisfied?(@user, phase: :registration),
                       @campaign.policies_satisfied?(@user, phase: :both)].all?

        I18n.t("registration.user_registration.messages.requirements_not_met")
      end

      def check_not_referenced_as_prerequisite
        prereq_policies = Registration::Policy.where(
          kind: Registration::Policy.kinds[:prerequisite_campaign],
          config: { "prerequisite_campaign_id" => @campaign.id }
        )

        dependent_campaigns_confirmed = Campaign
                                        .where(id: prereq_policies
                                        .map(&:registration_campaign_id))
                                        .joins(:user_registrations)
                                        .where(user_registrations:
                                        { status: UserRegistration.statuses[:confirmed] })
                                        .distinct
        return unless dependent_campaigns_confirmed.size.positive?

        names = dependent_campaigns_confirmed.pluck(:description)

        I18n.t("registration.user_registration.messages.dependent_campaigns_block_withdrawal",
               names: names.join(", "))
      end
    end
  end
end
