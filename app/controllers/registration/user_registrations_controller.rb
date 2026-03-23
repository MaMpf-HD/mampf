module Registration
  class UserRegistrationsController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    helper UserRegistrationsHelper, ItemsHelper, CampaignsHelper
    before_action :set_campaign, only: [:registrations_for_campaign, :create, :reset_preferences,
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
      lecture_id = params[:lecture_id]&.to_i
      @courses_seminars_campaigns = Registration::Campaign
                                    .where(campaignable_id: lecture_id)
                                    .where.not(status: :draft)
      @campaigns_by_id = @courses_seminars_campaigns.index_by(&:id)
      @campaignable_host_by_id = @campaigns_by_id.transform_values(&:campaignable)
      @eligibility_by_campaign_id = @campaigns_by_id.transform_values do |campaign|
        Registration::EligibilityService.new(
          campaign,
          current_user,
          phase_scope: :registration
        ).call
      end
      @items_by_campaign_id = @campaigns_by_id.transform_values do |campaign|
        campaign.registration_items.includes(:user_registrations)
      end
      # render layout: turbo_frame_request? ? "turbo_frame" : "application"
      render template: "registration/index",
             layout: turbo_frame_request? ? "turbo_frame" : "application"
    end

    def registrations_for_campaign
      target = resolve_render_target(@campaign)
      case target
      when :index
        redirect_to user_registrations_path,
                    notice: I18n.t("registration.user_registration.messages.campaign_unavailable")
      when :details
        init_details
        render template: "registration/main/show_main_campaign",
               layout: "application_no_sidebar"
      when :result
        init_result
        render template: "registration/main/show_result_main_campaign",
               layout: "application_no_sidebar"
      else # rubocop:disable Lint/DuplicateBranch
        redirect_to user_registrations_path,
                    notice: I18n.t("registration.user_registration.messages.campaign_unavailable")
      end
    end

    def create
      result = Registration::UserRegistration::LectureFcfsEditService
               .new(@campaign, current_user).register!(@item)
      respond_to_student_registration(result,
                                      I18n.t("registration.user_registration.messages.registration_success"))
    end

    def update
      pref_items = UserRegistration::PreferencesHandler
                   .new.pref_item_build_for_save(params[:preferences_json])
      result = Registration::UserRegistration::LecturePreferenceEditService
               .new(@campaign, current_user).update!(pref_items)
      respond_to_student_registration(result,
                                      I18n.t("registration.user_registration.messages.preferences_saved"))
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

    def render_not_found(exception)
      render json: { error: exception.message }, status: :unprocessable_content
    end

    def up
      handle_preference_action(:up)
    end

    def down
      handle_preference_action(:down)
    end

    def add
      handle_preference_action(:add)
    end

    def remove
      handle_preference_action(:remove)
    end

    def reset_preferences
      init_items
      init_preferences
      rerender_preferences
    end

    private

      def respond_to_student_registration(result, success_message)
        if result.success?
          init_details
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.update(
                view_context.dom_id(@campaign, :main_student_registration_campaign),
                partial: "registration/main/campaign_card",
                locals: {
                  campaign: @campaign,
                  campaignable_host: @campaignable_host,
                  eligibility: @eligibility,
                  items: @items,
                  item_preferences: @item_preferences
                }
              )
            end
            format.html do
              redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                          notice: success_message
            end
          end
        else
          respond_with_flash(
            :alert,
            result.errors.join(", "),
            fallback_location: campaign_registrations_for_campaign_path(campaign_id: @campaign.id)
          )
        end
      end

      def render_turbo_stream_response
        streams = [turbo_stream.replace("flash-messages", partial: "flash/messages")]

        streams << turbo_stream.update(view_context.campaign_registrations_tab_count_id(@campaign),
                                       @campaign.user_registrations.distinct.count(:user_id))

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
          else
            streams << turbo_stream.replace("allocation-dashboard",
                                            partial: "registration/allocations/dashboard")
          end
        elsif params[:source] == "registrations"
          streams << turbo_stream.replace(view_context.campaign_user_registrations_list_id(@campaign),
                                          partial: "registration/user_registrations/index",
                                          locals: { campaign: @campaign })
        end

        render turbo_stream: streams
      end

      def load_allocation_data
        @dashboard = Registration::AllocationDashboard.new(@campaign)
      end

      def set_campaign
        id = params[:registration_campaign_id] || params[:campaign_id]
        @campaign = Registration::Campaign.find_by(id: id)
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

      def campaign_completed?
        return false unless @campaign.completed?

        respond_with_error(t("registration.campaign.errors.already_finalized"))
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
          respond_with_destroy_success(count)
        else
          respond_with_error(t("registration.user_registration.destroy_failed"))
        end
      end

      def respond_with_destroy_success(count)
        message = t("registration.user_registration.destroyed_all_for_user", count: count)
        respond_to do |format|
          format.html do
            redirect_back_or_to(registration_campaign_path(@campaign),
                                notice: message)
          end
          format.turbo_stream do
            flash.now[:notice] = message
            render_turbo_stream_response
          end
        end
      end

      def set_item
        @item = Registration::Item.find(params[:item_id])
      end

      def resolve_render_target(campaign)
        case campaign.status.to_sym
        when :draft
          :index
        when :open, :closed, :processing
          :details
        when :completed
          :result
        else
          :index
        end
      end

      def init_details
        init_eligibility
        init_items
        init_campaignable_host
        init_preferences if @campaign.preference_based?
      end

      def init_eligibility
        @eligibility = Registration::EligibilityService.new(@campaign, current_user,
                                                            phase_scope: :registration).call
      end

      def init_result
        init_selected_items
        init_succeed_items
        succeed_ids = @items_succeed.pluck(:id)
        @status_items_selected = @items_selected.each_with_object({}) do |i, hash|
          hash[i.id] = succeed_ids.include?(i.id) ? "confirmed" : "dismissed"
        end
        init_campaignable_host
        init_preferences if @campaign.preference_based?
      end

      def init_selected_items
        @items_selected = @campaign.registration_items
                                   .includes(:user_registrations)
                                   .where(user_registrations: { user_id: current_user.id })
      end

      def init_succeed_items
        @items_succeed = Rosters::StudentMainResultResolver
                         .new(@campaign, current_user).succeed_items
        @item_succeed = @items_succeed.first || nil
      end

      def init_items
        @items = @campaign.registration_items.includes(:user_registrations)
      end

      def init_campaignable_host
        @campaignable_host = @campaign.campaignable
      end

      def init_preferences
        @item_preferences = UserRegistration::PreferencesHandler.new
                                                                .preferences_info(@campaign,
                                                                                  current_user)
      end

      def handle_preference_action(action)
        @campaign = @item.registration_campaign
        init_items
        @item_preferences = UserRegistration::PreferencesHandler
                            .new.public_send(action, params[:item_id],
                                             params[:preferences_json])
        rerender_preferences
      end

      def rerender_preferences
        render partial: "registration/main/pb/preferences_workspace",
               locals: { item_preferences: @item_preferences, campaign: @campaign, items: @items }
      end
  end
end
