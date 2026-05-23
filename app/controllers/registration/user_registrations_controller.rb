module Registration
  class UserRegistrationsController < ApplicationController
    helper ::UserRegistrationsHelper, ::EligibilityHelper,
           ItemsHelper, CampaignsHelper
    before_action :set_lecture, only: [:index]
    before_action :set_campaign, only: [:create, :destroy, :destroy_for_user]
    before_action :set_locale
    before_action :set_item, only: [:create, :destroy, :add]

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

    def index
      authorize! :index, @lecture

      @campaigns_details = ::UserRegistrations::LectureCampaignsService
                           .new(@lecture, current_user)
                           .call
      @rosterized_entries = Rosters::StudentMaterializedResultResolver
                            .new(current_user)
                            .all_rosterized_for_lecture(@lecture)
      @self_rosterables = Rosters::SelfRosterOptionsQuery.new(@lecture, current_user)
                                                         .call
      render template: "user_registrations/index",
             layout: turbo_frame_request? ? "turbo_frame" : "application"
    end

    def create
      authorize! :create, @item.registration_campaign.campaignable

      result = ::UserRegistrations::LectureFcfsEditService
               .new(@campaign, current_user).register!(@item)
      respond_to_student_registration(result,
                                      I18n.t("registration.user_registration.messages." \
                                             "registration_success"))
    end

    def destroy
      authorize! :destroy, @item.registration_campaign.campaignable

      result = ::UserRegistrations::LectureFcfsEditService
               .new(@campaign, current_user).withdraw!(@item)
      respond_to_student_registration(result,
                                      I18n.t("registration.user_registration.messages.withdrawn"))
    end

    def add
      @campaign = @item.registration_campaign
      authorize! :add, @campaign.campaignable

      pref_items = ::UserRegistrations::PreferencesHandler
                   .new.pref_item_build_with_rank(@campaign, current_user,
                                                  params[:item_id], params[:rank])
      result = ::UserRegistrations::LecturePreferenceEditService
               .new(@campaign, current_user).update!(pref_items)
      respond_to_student_registration(
        result,
        I18n.t("registration.user_registration.messages.preferences_saved")
      )
    end

    private

      def respond_to_student_registration(result, success_message)
        if result.success?
          flash.now[:notice] = success_message
          respond_to do |format|
            format.turbo_stream do
              @details = ::UserRegistrations::CampaignDetailsService
                         .new(@campaign, current_user)
                         .call
              render turbo_stream: [
                turbo_stream.replace("flash-messages", partial: "flash/messages"),
                turbo_stream.update(
                  view_context.dom_id(@campaign, :main_student_registration_campaign),
                  partial: "user_registrations/campaign_card",
                  locals: { details: @details, campaign: @campaign }
                )
              ]
            end
            format.html do
              redirect_to lecture_user_registrations_path(@campaign.campaignable),
                          notice: success_message
            end
          end
        else
          respond_with_flash(
            :alert,
            result.errors.join(", "),
            fallback_location: lecture_user_registrations_path(@campaign.campaignable)
          )
        end
      end

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
        id = params[:registration_campaign_id] || params[:campaign_id]
        @campaign = Registration::Campaign.find_by(id: id)
        return if @campaign

        respond_with_flash(:alert, t("registration.campaign.not_found"),
                           fallback_location: root_path)
      end

      def set_locale
        I18n.locale = current_user&.locale.presence || I18n.default_locale
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

      def set_item
        @item = Registration::Item.find(params[:item_id])
        return if @item

        respond_with_flash(:alert, t("registration.item.not_found"),
                           fallback_location: root_path)
      end

      def set_lecture
        lecture_id = params[:lecture_id]&.to_i
        @lecture = Lecture.find_by(id: lecture_id)
        return if @lecture

        respond_with_flash(:alert, t("registration.lecture.not_found"),
                           fallback_location: root_path)
      end
  end
end
