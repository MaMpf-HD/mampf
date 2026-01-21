module Registration
  class UserRegistrationsController < ApplicationController
    before_action :set_locale
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    helper UserRegistrationsHelper
    before_action :set_campaign, only: [:registrations_for_campaign, :create, :reset_preferences,
                                        :update, :destroy_for_user]
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
      @courses_seminars_campaigns = Registration::Campaign.all
      @eligibilities = @courses_seminars_campaigns.index_with do |c|
        Registration::EligibilityService.new(c, current_user,
                                             phase_scope: :registration).call
      end
      render template: "registration/index", layout: "application_no_sidebar"
    end

    def registrations_for_campaign
      target = resolve_render_target(@campaign)
      case target
      when :lecture_index, :exam_index
        redirect_to user_registrations_path,
                    notice: I18n.t("registration.messages.campaign_unavailable")
      when :lecture_details
        init_details
        render template: "registration/main/show_main_campaign",
               layout: "application_no_sidebar"
      when :exam_details
        raise(NotImplementedError, "Exam campaignable_type not supported yet")
      when :lecture_result
        init_result
        render template: "registration/main/show_result_main_campaign",
               layout: "application_no_sidebar"
      when :exam_result # rubocop:disable Lint/DuplicateBranch
        raise(NotImplementedError, "Exam campaignable_type not supported yet")
      else # rubocop:disable Lint/DuplicateBranch
        redirect_to user_registrations_path,
                    notice: I18n.t("registration.messages.campaign_unavailable")
      end
    end

    def create
      if @campaign.lecture_based?
        result = Registration::UserRegistration::LectureFcfsEditService
                 .new(@campaign, current_user, @item).register!
        if result.success?
          redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                      notice: I18n.t("registration.messages.registration_success")
        else
          redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                      alert: result.errors.join(", ")
        end
      elsif @campaign.exam_based?
        raise(NotImplementedError, "Exam campaignable_type not supported yet")
      end
    end

    def update
      if @campaign.lecture_based?
        pref_items =
          UserRegistration::PreferencesHandler
          .new
          .pref_item_build_for_save(params[:preferences_json])
        result = Registration::UserRegistration::LecturePreferenceEditService
                 .new(@campaign, current_user).update!(pref_items)
        if result.success?
          redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                      notice: I18n.t("registration.messages.preferences_saved")
        else
          respond_with_flash(
            :alert,
            result.errors.join(", "),
            fallback_location: campaign_registrations_for_campaign_path(campaign_id: @campaign.id)
          )
        end
      elsif @campaign.exam_based?
        raise(NotImplementedError, "Exam campaignable_type not supported yet")
      end
    end

    def destroy
      @user_registration = @item.user_registrations.find_by!(user_id: current_user.id,
                                                             status: :confirmed)
      @campaign = @user_registration.registration_campaign

      if @campaign.lecture_based?
        result = Registration::UserRegistration::LectureFcfsEditService
                 .new(@campaign, current_user, @item).withdraw!
        if result.success?
          redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                      notice: I18n.t("registration.messages.withdrawn")
        else
          redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                      alert: result.errors.join(", ")
        end
      elsif @campaign.exam_based?
        raise(NotImplementedError, "Exam campaignable_type not supported yet")
      end
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
      @items = @campaign.registration_items.includes(:user_registrations)
      init_preferences
      rerender_preferences
    end

    private

      def render_turbo_stream_response
        streams = [turbo_stream.replace("flash-messages", partial: "flash/messages")]

        streams << turbo_stream.update("registrations-tab-count",
                                       @campaign.user_registrations.distinct.count(:user_id))

        if params[:source] == "allocation"
          load_allocation_data
          streams << turbo_stream.replace("allocation-dashboard",
                                          partial: "registration/allocations/dashboard")
        elsif params[:source] == "registrations"
          streams << turbo_stream.replace("user-registrations-list",
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
          @campaign.lecture_based? ? :lecture_index : :exam_index
        when :open, :closed, :processing
          @campaign.lecture_based? ? :lecture_details : :exam_details
        when :completed
          @campaign.lecture_based? ? :lecture_result : :exam_result
        else
          :lecture_index
        end
      end

      def init_details
        @eligibility = Registration::EligibilityService.new(@campaign, current_user,
                                                            phase_scope: :registration).call
        @items = @campaign.registration_items.includes(:user_registrations)
        @campaignable_host = @campaign.campaignable
        init_preferences if @campaign.preference_based?
      end

      def init_result
        @items_selected = @campaign.registration_items
                                   .includes(:user_registrations)
                                   .where(user_registrations: { user_id: current_user.id })
        @items_succeed = Rosters::StudentMainResultResolver
                         .new(@campaign, current_user).succeed_items
        @item_succeed = @items_succeed.first || nil
        succeed_ids = @items_succeed.pluck(:id)
        @status_items_selected = @items_selected.each_with_object({}) do |i, hash|
          hash[i.id] = succeed_ids.include?(i.id) ? "confirmed" : "dismissed"
        end
        @campaignable_host = @campaign.campaignable
        init_preferences if @campaign.preference_based?
      end

      def init_preferences
        @item_preferences = UserRegistration::PreferencesHandler.new
                                                                .preferences_info(@campaign,
                                                                                  current_user)
      end

      def handle_preference_action(action)
        @campaign = @item.registration_campaign
        @items = @campaign.registration_items.includes(:user_registrations)
        handler = UserRegistration::PreferencesHandler.new
        @item_preferences = handler.public_send(action, params[:item_id],
                                                params[:preferences_json])
        rerender_preferences
      end

      def rerender_preferences
        render partial: "registration/main/pb/preferences_workspace",
               locals: { item_preferences: @item_preferences, campaign: @campaign, items: @items }
      end
  end
end
