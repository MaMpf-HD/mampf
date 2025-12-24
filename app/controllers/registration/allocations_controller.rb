module Registration
  class AllocationsController < ApplicationController
    before_action :set_campaign
    before_action :set_locale

    def current_ability
      @current_ability ||= RegistrationCampaignAbility.new(current_user)
    end

    def create
      authorize! :allocate, @campaign
      if @campaign.closed?
        Registration::AllocationService.new(@campaign).allocate!
        respond_with_success(t("registration.allocation.started"))
      else
        respond_with_error(t("registration.allocation.errors.wrong_status"))
      end
    end

    def finalize
      authorize! :finalize, @campaign

      guard = Registration::FinalizationGuard.new(@campaign)
      result = guard.check

      unless result.success?
        respond_with_error(result.error_message)
        return
      end

      if @campaign.finalize!
        respond_with_success(t("registration.campaign.finalized"))
      else
        respond_with_error(@campaign.errors.full_messages.join(", "))
      end
    end

    private

      def set_campaign
        @campaign = Registration::Campaign.find_by(id: params[:registration_campaign_id])
      end

      def set_locale
        I18n.locale = @campaign&.locale_with_inheritance || I18n.locale
      end

      def respond_with_success(message)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign), notice: message
          end
          format.turbo_stream do
            flash.now[:notice] = message
            render turbo_stream: [
              turbo_stream.update("campaigns_container",
                                  partial: "registration/campaigns/card_body_show",
                                  locals: { campaign: @campaign }),
              stream_flash
            ]
          end
        end
      end

      def respond_with_error(message)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign), alert: message
          end
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: stream_flash
          end
        end
      end
  end
end
