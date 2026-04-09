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

      unless @campaign.preference_based?
        respond_with_flash(
          :alert,
          "Allocation can only be triggered for preference-based campaigns. " \
          "As a user, you should never see this error, please contact the MaMpf team.",
          redirect_path: registration_campaign_path(@campaign)
        )
        return
      end

      unless @campaign.closed? || @campaign.processing?
        respond_with_flash(:alert, t("registration.allocation.errors.wrong_status"),
                           redirect_path: registration_campaign_path(@campaign))
        return
      end

      Registration::AllocationService.new(@campaign).allocate!
      @dashboard = Registration::AllocationDashboard.new(@campaign)

      respond_with_flash(
        :notice,
        t("registration.allocation.started"),
        redirect_path: registration_campaign_allocation_path(@campaign)
      ) do
        turbo_stream.update("campaigns_container",
                            partial: "registration/campaigns/card_body_index",
                            locals: {
                              lecture: @campaign.campaignable,
                              expanded_campaign_id: @campaign.id
                            })
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
        lecture = @campaign.campaignable
        respond_with_flash(:notice, t("registration.campaign.finalized"),
                           redirect_path: registration_campaign_path(@campaign)) do
          [
            turbo_stream.update("campaigns_container",
                                partial: "registration/campaigns/card_body_index",
                                locals: {
                                  lecture: lecture,
                                  expanded_campaign_id: @campaign.id
                                }),
            *refresh_roster_streams(lecture)
          ]
        end
      else
        respond_with_flash(:alert, @campaign.errors.full_messages.join(", "),
                           redirect_path: registration_campaign_path(@campaign))
      end
    end

    private

      def set_campaign
        @campaign = Registration::Campaign.find_by(id: params[:registration_campaign_id])
        return if @campaign

        respond_with_flash(:alert, t("registration.campaign.not_found"), redirect_path: root_path)
      end

      def set_locale
        I18n.locale = @campaign&.locale_with_inheritance || I18n.locale
      end
  end
end
