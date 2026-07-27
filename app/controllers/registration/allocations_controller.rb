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
    rescue Registration::AllocationService::BlockedError
      @dashboard = Registration::AllocationDashboard.new(@campaign)

      respond_with_flash(
        :alert,
        t("registration.allocation.errors.policy_violation"),
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

      guard = Registration::FinalizationGuard.new(@campaign)
      result = guard.check

      unless result.success?
        # Redirect to dashboard to show errors
        redirect_to registration_campaign_allocation_path(@campaign),
                    alert: t("registration.allocation.errors.#{result.error_code}")
        return
      end

      if @campaign.finalize!
        lecture = @campaign.campaignable
        base_streams = [
          turbo_stream.update("campaigns_container",
                              partial: "registration/campaigns/card_body_index",
                              locals: {
                                lecture: lecture,
                                expanded_campaign_id: @campaign.id
                              }),
          *refresh_roster_streams(lecture)
        ]

        if @campaign.registerables.any?
          # The self-service modal is the post-finalization surface, so we do
          # NOT also pop a flash over it (fixed, top-of-screen, it would cover
          # the modal). The finalization summary is folded into the modal.
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: base_streams + [
                turbo_stream.update(
                  "modal-container",
                  partial: "registration/campaigns/self_service_modal",
                  locals: { campaign: @campaign, summary: finalization_summary }
                )
              ]
            end
            format.html do
              redirect_to registration_campaign_path(@campaign),
                          notice: finalization_notice
            end
          end
        else
          respond_with_flash(:notice, finalization_notice,
                             redirect_path: registration_campaign_path(@campaign)) do
            base_streams
          end
        end
      else
        respond_with_flash(:alert, @campaign.errors.full_messages.join(", "),
                           redirect_path: registration_campaign_path(@campaign))
      end
    rescue Registration::Campaign::FinalizationBlockedError
      redirect_to registration_campaign_allocation_path(@campaign),
                  alert: t("registration.allocation.errors.policy_violation")
    end

    private

      def finalization_notice
        [t("registration.campaign.finalized"), finalization_summary]
          .compact.join(" ")
      end

      # The "some students could not be placed" warning, or nil when everyone
      # got a spot. Shown in the flash (no groups) or inside the modal.
      def finalization_summary
        rejected_count = @campaign.open_rejected_count
        unassigned_count = @campaign.unassigned_users.count
        return if rejected_count.zero? && unassigned_count.zero?

        parts = []
        if rejected_count.positive?
          parts << t("registration.campaign.finalization_summary.rejected",
                     count: rejected_count)
        end
        if unassigned_count.positive?
          parts << t("registration.campaign.finalization_summary.unassigned",
                     count: unassigned_count)
        end
        parts << t("registration.campaign.finalization_summary.manual_addition")
        parts.join(" ")
      end

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
