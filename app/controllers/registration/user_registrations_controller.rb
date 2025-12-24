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
            redirect_to registration_campaign_path(@campaign),
                        notice: t("registration.user_registration.destroyed")
          end
        end
      else
        respond_with_error(@registration.errors.full_messages.join(", "))
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
