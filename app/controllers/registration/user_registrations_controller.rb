module Registration
  class UserRegistrationsController < ApplicationController
    before_action :set_campaign
    before_action :set_locale

    def current_ability
      @current_ability ||= RegistrationUserRegistrationAbility.new(current_user)
    end

    def destroy_for_user
      return if campaign_completed?

      @user = User.find(params[:user_id])
      registrations = @campaign.user_registrations.where(user: @user)

      return if no_registrations_found?(registrations)

      # Authorize based on the first registration (all belong to same campaign)
      authorize! :destroy, registrations.first

      destroy_registrations(registrations)
    end

    private

      def evaluate_turbo_stream_response
        streams = [turbo_stream.replace("flash-messages", partial: "flash/messages")]

        if ["allocation", "allocation_embedded"].include?(params[:source])
          load_allocation_data
          if params[:source] == "allocation_embedded"
            streams << turbo_stream.replace("allocation-dashboard",
                                            partial: "registration/allocations/dashboard",
                                            locals: {
                                              campaign: @campaign,
                                              dashboard: @dashboard,
                                              embedded: true
                                            })
            streams << turbo_stream.replace(
              helpers.campaign_actions_id(@campaign),
              partial: "registration/campaigns/card_body_actions",
              locals: {
                campaign: @campaign,
                has_violators: @dashboard.policy_violations.present?
              }
            )
          else
            streams << turbo_stream.replace("allocation-dashboard",
                                            partial: "registration/allocations/dashboard",
                                            locals: {
                                              campaign: @campaign,
                                              dashboard: @dashboard
                                            })
          end
        end

        streams
      end

      def load_allocation_data
        @dashboard = Registration::AllocationDashboard.new(@campaign)
      end

      def set_campaign
        @campaign = Registration::Campaign.find_by(id: params[:registration_campaign_id])
        return if @campaign

        respond_with_flash(:alert, t("registration.campaign.not_found"),
                           fallback_location: root_path)
      end

      def set_locale
        I18n.locale = @campaign&.campaignable&.locale_with_inheritance || I18n.locale
      end

      def campaign_completed?
        return false unless @campaign.completed?

        respond_with_flash(:alert, t("registration.campaign.errors.already_finalized"),
                           fallback_location: registration_campaign_path(@campaign))
        true
      end

      def no_registrations_found?(registrations)
        return false if registrations.any?

        redirect_back_or_to(registration_campaign_path(@campaign),
                            alert: t("registration.user_registration.none"))
        true
      end

      def destroy_registrations(registrations)
        count = registrations.count

        if registrations.destroy_all
          respond_with_flash(:notice,
                             t("registration.user_registration.destroyed_all_for_user",
                               count: count),
                             fallback_location: registration_campaign_path(@campaign)) do
            evaluate_turbo_stream_response
          end
        else
          respond_with_flash(:alert, t("registration.user_registration.destroy_failed"),
                             fallback_location: registration_campaign_path(@campaign))
        end
      end
  end
end
