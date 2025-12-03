module Registration
  class LectureFcfsEditService
    def initialize(campaign, item, user)
      @campaign = campaign
      @item = item
      @user = user
    end

    def register!
      ActiveRecord::Base.transaction do
        @item.lock!
        validate_register!

        # hard delete all registrations of current user in current campaign
        registrations_current_campaign = @campaign.user_registrations.where(user_id: @user.id)
        registrations_current_campaign.destroy_all

        Registration::UserRegistration.create!(
          registration_campaign: @campaign,
          registration_item: @item,
          user: @user,
          status: :confirmed
        )
      end
    end

    # must hard delete the result, or else cannot trace the "submitted options"
    # the downside effect is that we cannot trace the withdraw time of user
    def withdraw!
      validate_withdraw!
      registration = @item.user_registrations.find_by!(user: @user, status: :confirmed)
      registration.destroy!
    end

    private

      # Validation for creating registration in lecture based registration
      # 0. Check open for registration
      # 1. Check if user has already registered for this campaign
      # 2. Check if item still has capacity
      # 3. Check if user satisfies all policies (phase: registration and both)
      def validate_register!
        unless @campaign.open_for_registrations?
          raise(Registration::RegistrationError,
                I18n.t("registration.messages.campaign_not_opened"))
        end
        if @campaign.user_registrations.exists?(user_id: @user.id, status: :confirmed)
          raise(Registration::RegistrationError, I18n.t("registration.messages.already_registered"))
        end

        unless @item.still_have_capacity?
          raise(RegistrationError,
                I18n.t("registration.messages.no_slots"))
        end
        unless [@campaign.policies_satisfied?(@user, phase: :registration),
                @campaign.policies_satisfied?(@user, phase: :both)].all?
          raise(Registration::RegistrationError,
                I18n.t("registration.messages.requirements_not_met"))
        end
      end

      # Validation for widthdrawing registration in lecture based registration
      # 0. Check open to withdraw
      # 1. Check if withdrawing current campaign may lead to fail in another "confirmed" campaign
      def validate_withdraw!
        unless @campaign.open_for_withdrawals?
          raise(Registration::RegistrationError,
                I18n.t("registration.messages.campaign_not_opened"))
        end

        # prereq_query = "{ prerequisite_campaign_id: #{@campaign.id} }"
        prereq_policies = Registration::Policy.where(
          kind: Registration::Policy.kinds[:prerequisite_campaign],
          config: { "prerequisite_campaign_id" => @campaign.id }
        )
        dependent_campaigns_confirmed = Campaign
                                        .where(id: prereq_policies.map(&:registration_campaign_id))
                                        .joins(:user_registrations)
                                        .where(user_registrations: { status: UserRegistration.statuses[:confirmed] })
                                        .distinct
        return unless dependent_campaigns_confirmed.size.positive?

        names = dependent_campaigns_confirmed.pluck(:title)
        raise(Registration::RegistrationError,
              I18n.t("registration.messages.dependent_campaigns_block_withdrawal",
                     names: names.join(", ")))
      end
  end
end
