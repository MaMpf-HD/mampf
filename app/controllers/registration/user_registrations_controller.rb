module Registration
  class UserRegistrationsController < ApplicationController
    before_action :set_campaign
    before_action :set_locale

    def current_ability
      @current_ability ||= RegistrationUserRegistrationAbility.new(current_user)
    end

    def destroy
      @registration = @campaign.user_registrations.find(params[:id])
      authorize! :destroy, @registration

      if @registration.destroy
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.remove(@registration) }
          format.html do
            redirect_back_or_to(registration_campaign_path(@campaign),
                                notice: t("registration.user_registration.destroyed"))
          end
        end
      else
        respond_with_error(@registration.errors.full_messages.join(", "))
      end
    end

    def destroy_for_user
      @user = User.find(params[:user_id])
      registrations = @campaign.user_registrations.where(user: @user)

      if registrations.empty?
        redirect_back_or_to(registration_campaign_path(@campaign),
                            alert: t("registration.user_registration.none"))
        return
      end

      # Authorize based on the first registration (all belong to same campaign)
      authorize! :destroy, registrations.first

      if registrations.destroy_all
        redirect_back_or_to(registration_campaign_path(@campaign), notice: t("registration.user_registration.destroyed_all_for_user",
                                                                             count: registrations.count))
      else
        respond_with_error(t("registration.user_registration.destroy_failed"))
      end
    end

    private

      def set_campaign
        @campaign = Registration::Campaign.find(params[:campaign_id])
      end

      def set_locale
        I18n.locale = @campaign.campaignable.locale_with_inheritance
      end
  end
end
