module Registration
  class UserRegistrationsController < ApplicationController
    before_action :set_campaign
    before_action :set_locale

    def current_ability
      @current_ability ||= RegistrationUserRegistrationAbility.new(current_user)
    end

    def destroy_for_user
      if @campaign.completed?
        respond_with_error(t("registration.campaign.errors.already_finalized"))
        return
      end

      @user = User.find(params[:user_id])
      registrations = @campaign.user_registrations.where(user: @user)

      if registrations.empty?
        redirect_back_or_to(registration_campaign_path(@campaign),
                            alert: t("registration.user_registration.none"))
        return
      end

      # Authorize based on the first registration (all belong to same campaign)
      authorize! :destroy, registrations.first

      count = registrations.count

      if registrations.destroy_all
        respond_to do |format|
          format.html do
            redirect_back_or_to(registration_campaign_path(@campaign),
                                notice: t("registration.user_registration.destroyed_all_for_user",
                                          count: count))
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.user_registration.destroyed_all_for_user",
                                   count: count)
            render_turbo_stream_response
          end
        end
      else
        respond_with_error(t("registration.user_registration.destroy_failed"))
      end
    end

    private

      def render_turbo_stream_response
        streams = [turbo_stream.replace("flash-messages", partial: "flash/messages")]

        streams << turbo_stream.update("registrations-tab-count",
                                       @campaign.user_registrations.distinct.count(:user_id))

        if params[:source] == "allocation"
          load_allocation_data
          streams << turbo_stream.replace("allocation-dashboard",
                                          partial: "registration/allocations/show")
        elsif params[:source] == "registrations"
          streams << turbo_stream.replace("user-registrations-list",
                                          partial: "registration/user_registrations/index",
                                          locals: { campaign: @campaign })
        end

        render turbo_stream: streams
      end

      def load_allocation_data
        assignment = @campaign.user_registrations
                              .where(status: :confirmed)
                              .pluck(:user_id, :registration_item_id)
                              .to_h
        @stats = Registration::AllocationStats.new(@campaign, assignment)
        @unassigned_students = User.where(id: @stats.unassigned_user_ids)
                                   .order(:email)

        guard_result = Registration::FinalizationGuard.new(@campaign).check
        @policy_violations = guard_result.success? ? [] : guard_result.data
      end

      def set_campaign
        @campaign = Registration::Campaign.find_by(id: params[:registration_campaign_id])
        return if @campaign

        respond_with_error(t("registration.campaign.not_found"), redirect_path: root_path)
      end

      def set_locale
        I18n.locale = @campaign&.campaignable&.locale_with_inheritance || I18n.locale
      end

      def respond_with_error(message, redirect_path: nil)
        respond_to do |format|
          format.html do
            path = redirect_path || registration_campaign_path(@campaign)
            redirect_back_or_to(path, alert: message)
          end
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: stream_flash
          end
        end
      end
  end
end
