module Registration
  class AllocationsController < ApplicationController
    before_action :set_campaign

    def create
      authorize! :allocate, @campaign

      if @campaign.closed?
        Registration::AllocationService.new(@campaign).allocate!
        redirect_to registration_campaign_path(@campaign),
                    notice: t("registration.allocation.started")
      else
        redirect_to registration_campaign_path(@campaign),
                    alert: t("registration.allocation.errors.wrong_status")
      end
    rescue StandardError => e
      redirect_to registration_campaign_path(@campaign),
                  alert: t("registration.allocation.errors.failed", error: e.message)
    end

    def finalize
      authorize! :finalize, @campaign

      guard = Registration::FinalizationGuard.new(@campaign)
      result = guard.check

      unless result.success?
        redirect_to registration_campaign_path(@campaign),
                    alert: result.error_message
        return
      end

      if @campaign.finalize!
        redirect_to registration_campaign_path(@campaign),
                    notice: t("registration.campaign.finalized")
      else
        redirect_to registration_campaign_path(@campaign),
                    alert: @campaign.errors.full_messages.join(", ")
      end
    end

    private

      def set_campaign
        @campaign = Registration::Campaign.find(params[:campaign_id])
      end
  end
end
