module Registration
  class LectureFcfsService
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

    def withdraw!
      validate_withdraw!
      registration = @item.user_registrations.find_by!(user: @user, status: :confirmed)
      registration.update!(status: :rejected)
    end

    private

      # Validation for creating registration in lecture based registration
      # 0. Check open for registration
      # 1. Check if user has already registered for this campaign
      # 2. Check if item still has capacity
      # 3. Check if user satisfies all policies (phase: registration and both)
      def validate_register!
        unless @campaign.open_for_registrations?
          raise(RegistrationError, t("registration.messages.campaign_not_opened"))
        end
        if @campaign.user_registrations.exists?(user_id: @user.id, status: :confirmed)
          raise(RegistrationError, t("registration.messages.already_registered"))
        end

        unless @item.still_have_capacity?
          raise(RegistrationError,
                t("registration.messages.no_slots"))
        end
        unless [@campaign.policies_satisfied?(@user, phase: :registration),
                @campaign.policies_satisfied?(@user, phase: :both)].all?
          raise(RegistrationError, t("registration.messages.requirements_not_met"))
        end
      end

      # Validation for widthdrawing registration in lecture based registration
      # 0. Check open for registration
      def validate_withdraw!
        return if @campaign.open_for_registrations?

        raise(RegistrationError, t("registration.messages.campaign_not_opened"))
      end
  end
end
