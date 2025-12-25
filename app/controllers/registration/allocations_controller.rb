module Registration
  class AllocationsController < ApplicationController
    before_action :set_campaign
    before_action :set_locale

    def current_ability
      @current_ability ||= RegistrationCampaignAbility.new(current_user)
    end

    def show
      authorize! :view_allocation, @campaign
      load_allocation_data

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("campaigns_container",
                                                   partial: "registration/allocations/show")
        end
      end
    end

    def create
      authorize! :allocate, @campaign
      if @campaign.closed? || @campaign.processing?
        Registration::AllocationService.new(@campaign).allocate!
        load_allocation_data

        respond_to do |format|
          format.html do
            redirect_to registration_campaign_allocation_path(@campaign),
                        notice: t("registration.allocation.started")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.allocation.started")
            render turbo_stream: [
              turbo_stream.update("campaigns_container",
                                  partial: "registration/allocations/show"),
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

      guard = Registration::FinalizationGuard.new(@campaign)
      # Allow skipping policies if 'force' param is present
      result = guard.check(ignore_policies: params[:force] == "true")

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
      end

      def set_locale
        I18n.locale = @campaign&.locale_with_inheritance || I18n.locale
      end

      def load_allocation_data
        assignment = @campaign.user_registrations
                              .where(status: :confirmed)
                              .pluck(:user_id, :registration_item_id)
                              .to_h
        @stats = Registration::AllocationStats.new(@campaign, assignment)
        @unassigned_students = User.where(id: @stats.unassigned_user_ids)
                                   .order(:email)

        # Check for policy violations (dry run)
        guard_result = Registration::FinalizationGuard.new(@campaign).check
        @policy_violations = guard_result.success? ? [] : guard_result.data
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
