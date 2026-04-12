module Registration
  class UserRegistrationsController < ApplicationController
    helper UserRegistrationsHelper, ItemsHelper, CampaignsHelper
    before_action :set_lecture, only: [:index]
    before_action :set_campaign, only: [:create, :reset_preferences,
                                        :update, :destroy_for_user]
    before_action :set_locale
    before_action :set_item, only: [:create, :destroy, :up, :down, :add, :remove]

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
      @campaigns_details = Campaign::LectureCampaignsService
                           .new(@lecture, current_user)
                           .call
      @rosterized_entries = Rosters::StudentMaterializedResultResolver
                            .new(current_user)
                            .all_rosterized_for_lecture(@lecture)
      @self_rosterables = Rosters::SelfRosterOptionsQuery.new(@lecture, current_user)
                                                         .call
      render template: "registration/main/index",
             layout: turbo_frame_request? ? "turbo_frame" : "application"
    end

    def create
      result = Registration::UserRegistration::LectureFcfsEditService
               .new(@campaign, current_user).register!(@item)
      respond_to_student_registration(result,
                                      I18n.t("registration.user_registration.messages." \
                                             "registration_success"))
    end

    def update
      pref_items = UserRegistration::PreferencesHandler
                   .new.pref_item_build_for_save(params[:preferences_json])
      result = Registration::UserRegistration::LecturePreferenceEditService
               .new(@campaign, current_user).update!(pref_items)
      respond_to_student_registration(result,
                                      I18n.t("registration.user_registration.messages." \
                                             "registration_success"))
    end

    def destroy
      @campaign = @item.user_registrations.find_by!(user_id: current_user.id,
                                                    status: :confirmed)
                       .registration_campaign
      result = Registration::UserRegistration::LectureFcfsEditService
               .new(@campaign, current_user).withdraw!(@item)
      respond_to_student_registration(result,
                                      I18n.t("registration.user_registration.messages.withdrawn"))
    end

    def up
      locals = handle_preference_action(:up)
      rerender_preferences(locals)
    end

    def down
      locals = handle_preference_action(:down)
      rerender_preferences(locals)
    end

    def add
      locals = handle_preference_action(:add)
      rerender_preferences(locals)
    end

    def remove
      locals = handle_preference_action(:remove)
      rerender_preferences(locals)
    end

    def reset_preferences
      locals = Registration::Campaign::CampaignDetailsService.new(@campaign, current_user)
                                                             .preferences_info
      rerender_preferences(locals)
    end

    private

      def respond_to_student_registration(result, success_message)
        if result.success?
          flash.now[:notice] = success_message
          respond_to do |format|
            format.turbo_stream do
              @details = Registration::Campaign::CampaignDetailsService.new(@campaign,
                                                                            current_user)
                                                                       .call
              render turbo_stream: [
                turbo_stream.replace("flash-messages", partial: "flash/messages"),
                turbo_stream.update(
                  view_context.dom_id(@campaign, :main_student_registration_campaign),
                  partial: "registration/main/campaign_card",
                  locals: { details: @details, campaign: @campaign }
                )
              ]
            end
            format.html do
              redirect_to lecture_campaign_registrations_path(@campaign.campaignable),
                          notice: success_message
            end
          end
        else
          respond_with_flash(
            :alert,
            result.errors.join(", "),
            fallback_location: lecture_campaign_registrations_path(@campaign.campaignable)
          )
        end
      end

      def rerender_preferences(locals)
        render turbo_stream: turbo_stream.update(
          view_context.dom_id(@campaign, :preferences_workspace),
          partial: "registration/main/pb/preferences_workspace",
          locals: locals
        )
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

      def handle_preference_action(action)
        @campaign = @item.registration_campaign
        items = @campaign.registration_items.includes(:user_registrations)
        item_preferences = UserRegistration::PreferencesHandler
                           .new.public_send(action, params[:item_id],
                                            params[:preferences_json])
        @campaign.reload
        { item_preferences: item_preferences,
          campaign: @campaign,
          items: items }
      end
  end
end
