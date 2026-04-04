module Registration
  class AllocationsController < ApplicationController
    include Registration::RosterStreamRefreshable

    before_action :set_campaign
    before_action :set_locale

    def current_ability
      @current_ability ||= RegistrationCampaignAbility.new(current_user)
    end

    def show
      authorize! :view_allocation, @campaign
      @dashboard = Registration::AllocationDashboard.new(@campaign)

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "campaigns_container",
            partial: "registration/campaigns/card_body_index",
            locals: {
              lecture: @campaign.campaignable,
              expanded_campaign_id: @campaign.id
            }
          )
        end
      end
    end

    def create
      authorize! :allocate, @campaign
      if @campaign.closed? || @campaign.processing?
        Registration::AllocationService.new(@campaign).allocate!
        @dashboard = Registration::AllocationDashboard.new(@campaign)

        respond_to do |format|
          format.html do
            redirect_to registration_campaign_allocation_path(@campaign),
                        notice: t("registration.allocation.started")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.allocation.started")
            render turbo_stream: [
              turbo_stream.update("campaigns_container",
                                  partial: "registration/campaigns/card_body_index",
                                  locals: {
                                    lecture: @campaign.campaignable,
                                    expanded_campaign_id: @campaign.id
                                  }),
              stream_flash
            ]
          end
        end
      else
        respond_with_error(t("registration.allocation.errors.wrong_status"))
      end
    end

    def finalize
      authorize! :finalize, @campaign

      force = params[:force] == "true"
      authorize!(:force_finalize, @campaign) if force

      guard = Registration::FinalizationGuard.new(@campaign)
      result = guard.check(ignore_policies: force)

      unless result.success?
        # Redirect to dashboard to show errors
        redirect_to registration_campaign_allocation_path(@campaign),
                    alert: t("registration.allocation.errors.#{result.error_code}")
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
        return if @campaign

        respond_with_error(t("registration.campaign.not_found"), redirect_path: root_path)
      end

      def set_locale
        I18n.locale = @campaign&.locale_with_inheritance || I18n.locale
      end

      def respond_with_success(message)
        lecture = @campaign.campaignable
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign), notice: message
          end
          format.turbo_stream do
            flash.now[:notice] = message
            streams = [
              turbo_stream.update("campaigns_container",
                                  partial: "registration/campaigns/card_body_index",
                                  locals: {
                                    lecture: lecture,
                                    expanded_campaign_id: @campaign.id
                                  }),
              stream_flash
            ]
            streams += refresh_roster_streams(lecture)
            render turbo_stream: streams.compact
          end
        end
      end

      def respond_with_error(message, redirect_path: nil)
        respond_to do |format|
          format.html do
            path = redirect_path || registration_campaign_path(@campaign)
            redirect_to path, alert: message
          end
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: stream_flash
          end
        end
      end
  end
end
