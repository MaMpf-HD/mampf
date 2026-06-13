module Registration
  class UserRegistrationsController < ApplicationController
    helper ::UserRegistrationsHelper, ::EligibilityHelper,
           ItemsHelper, CampaignsHelper
    before_action :set_lecture, only: [:index]
    before_action :set_campaign,
                  only: [:create, :destroy, :destroy_for_user, :save_preferences]
    before_action :set_user_locale
    before_action :set_item, only: [:create, :destroy]

    def current_ability
      @current_ability ||= RegistrationUserRegistrationAbility.new(current_user)
    end

    def reject_for_user
      return if campaign_completed?

      @user = User.find(params[:user_id])
      registrations = @campaign.user_registrations.where(user: @user)

      return if no_registrations_found?(registrations)

      # Authorize based on the first registration (all belong to same campaign)
      authorize! :destroy, registrations.first

      reject_registrations(registrations)
    end

    def index
      authorize! :index, @lecture

      @campaigns_details = ::UserRegistrations::LectureCampaignsService
                           .new(@lecture, current_user)
                           .call
      @rosterized_entries = Rosters::StudentMaterializedResultResolver
                            .new(current_user)
                            .all_rosterized_for_lecture(@lecture)
      @self_rosterables = Rosters::SelfRosterOptionsQuery.new(@lecture, current_user).call
      render template: "user_registrations/index",
             layout: turbo_frame_request? ? "turbo_frame" : "application"
    end

    def create
      authorize! :create, @item.registration_campaign.campaignable

      result = ::UserRegistrations::LectureFirstComeFirstServedEditService
               .new(@campaign, current_user).register!(@item)
      respond_to_student_registration(result,
                                      I18n.t("registration.user_registration.messages." \
                                             "registration_success"))
    end

    def destroy
      @campaign = @item.registration_campaign
      authorize! :destroy, @campaign.campaignable

      result = ::UserRegistrations::LectureFirstComeFirstServedEditService
               .new(@campaign, current_user).withdraw!(@item)
      respond_to_student_registration(result,
                                      I18n.t("registration.user_registration.messages.withdrawn"))
    end

    def save_preferences
      authorize! :add, @campaign.campaignable

      ranked_preferences = preference_params
      pref_items = ::UserRegistrations::PreferencesHandler
                   .new.pref_items_from_ranked_params(ranked_preferences)
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
                ),
                rosterized_entries_stream
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

      def rosterized_entries_stream
        turbo_stream.update(
          "student_registration_rosterized_entries",
          html: RosterizedEntriesComponent.new(
            rosterized_entries: Rosters::StudentMaterializedResultResolver
                                 .new(current_user)
                                 .all_rosterized_for_lecture(student_registration_lecture),
            lecture: student_registration_lecture,
            user: current_user
          ).render_in(view_context)
        )
      end

      def preference_params
        params.expect(preferences: preference_param_keys).to_h
      end

      def preference_param_keys
        (1..::UserRegistrations::PreferencesHandler::MAX_PREFERENCES).map(&:to_s)
      end

      def student_registration_lecture
        @student_registration_lecture ||= @campaign.campaignable
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
                has_violators: @dashboard.blockers?
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

      def reject_registrations(registrations)
        registrations = registrations.where.not(status: :rejected).to_a
        count = registrations.size
        reason_code = rejection_reason

        Registration::UserRegistration.transaction do
          registrations.each do |registration|
            registration.reject!(
              reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_MANUAL,
              reason_code: reason_code,
              reason_label:
              Registration::UserRegistration.built_in_rejection_reason_label(reason_code)
            )
          end
        end

        respond_with_flash(:notice,
                           t("registration.user_registration.rejected_all_for_user",
                             count: count),
                           fallback_location: registration_campaign_path(@campaign)) do
          evaluate_turbo_stream_response
        end
      rescue ActiveRecord::RecordInvalid
        respond_with_flash(:alert, t("registration.user_registration.reject_failed"),
                           fallback_location: registration_campaign_path(@campaign))
      end

      def rejection_reason
        if params[:reason] == Registration::UserRegistration::REJECTION_REASON_CODE_DEFERRED_DUE_TO_BLOCKER
          Registration::UserRegistration::REJECTION_REASON_CODE_DEFERRED_DUE_TO_BLOCKER
        else
          Registration::UserRegistration::REJECTION_REASON_CODE_WITHDRAWN_BY_TEACHER
        end
      end

      def set_item
        @item = Registration::Item.find_by(id: params[:item_id])
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
