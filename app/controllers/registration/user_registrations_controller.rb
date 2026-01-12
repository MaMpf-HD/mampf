module Registration
  class UserRegistrationsController < ApplicationController
    # Manages student registrations within a registration campaign.
    #
    # Registration behavior varies by allocation mode:
    # - First‑come, first‑served (FCFS): students register for individual items.
    #   Uses `create` for registration and `destroy` for withdrawal.
    #
    # - Preference‑based: students submit a ranked batch of items.
    #   Uses `update` to submit or modify preferences, including deregistration.
    #
    # - Exam registrations: expected to follow the FCFS single‑item model.

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    helper UserRegistrationsHelper
    before_action :set_locale
    before_action :set_campaign, only: [:registrations_for_campaign, :create, :reset_preferences,
                                        :update]
    before_action :set_item, only: [:create, :destroy, :up, :down, :add, :remove]

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

      def set_item
        @item = Registration::Item.find(params[:item_id])
      end

      def set_campaign
        @campaign = Registration::Campaign.find(params[:campaign_id])
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

      def set_locale
        I18n.locale = current_user.locale ||
                      @campaign&.locale_with_inheritance ||
                      @lecture&.locale_with_inheritance ||
                      I18n.locale
      end

      def init_details
        @eligibility = Registration::EligibilityService.new(@campaign, current_user,
                                                            phase_scope: :registration).call
        @items = @campaign.registration_items.includes(:user_registrations)
        @campaignable_host = @campaign.campaignable
        init_preferences if @campaign.preference_based?
      end

      def init_result
        type_register = @campaign.registration_items.first&.registration_type
        case type_register
        when "Tutorial"
          membership = TutorialMembership.where(source_campaign_id: 42).first
          @item_succeed = Registration::Item.where(registerable_type: "Tutorial",
                                                   registerable_id: membership.tutorial_id,
                                                   campaign_id: membership.source_campaign_id)
                                            .first
        when "Cohort"
          membership = CohortMembership.where(source_campaign_id: 42).first
          @item_succeed = Registration::Item.where(registerable_type: "Cohort",
                                                   registerable_id: membership.cohort_id,
                                                   campaign_id: membership.source_campaign_id)
                                            .first
        when "Talk"
          membership = SpeakerTalkJoin.where(source_campaign_id: 42).first
          @item_succeed = Registration::Item.where(registerable_type: "Talk",
                                                   registerable_id: membership.talk_id,
                                                   campaign_id: membership.source_campaign_id)
                                            .first
        when "Lecture"
          membership = LectureMembership.where(source_campaign_id: 42).first
          @item_succeed = Registration::Item.where(registerable_type: "Lecture",
                                                   registerable_id: membership.lecture_id,
                                                   campaign_id: membership.source_campaign_id)
                                            .first
        else
          @item_succeed = nil
        end
        @status_items_selected = @items_selected.index_with do |i|
          UserRegistration.where(registration_campaign_id: @campaign.id, user_id: current_user.id,
                                 registration_item_id: i.id).first&.status
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
