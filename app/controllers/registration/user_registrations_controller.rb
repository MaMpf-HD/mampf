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
    before_action :set_campaign, only: [:registrations_for_campaign, :create]
    before_action :set_item, only: [:create, :destroy]

    TempItemPreference = Struct.new(:item, :temp_preference_rank)

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
        render template: "registration/main/show_main_campaign", layout: "application_no_sidebar"
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
                      success: I18n.t("registration.messages.registration_success")
        else
          redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                      alert: result.errors.join(", ")
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
                      success: I18n.t("registration.messages.withdrawn")
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
      item_id = params[:item_id].to_i
      item = Registration::Item.find(item_id)
      @campaign = item.registration_campaign
      @item_preferences = Registration::UserRegistrations::PreferencesHandler
                          .new.up(item_id, params[:preferences_json])
      render partial: "registration/main/preferences_table",
             locals: { item_preferences: @item_preferences, campaign: @campaign }
    end

    def down
      item_id = params[:item_id].to_i
      item = Registration::Item.find(item_id)
      @campaign = item.registration_campaign
      @item_preferences = Registration::UserRegistrations::PreferencesHandler
                          .new.down(item_id, params[:preferences_json])

      render partial: "registration/main/preferences_table",
             locals: { item_preferences: @item_preferences, campaign: @campaign }
    end

    def add
      item_id = params[:item_id]
      item = Registration::Item.find(item_id)
      @campaign = item.registration_campaign
      @item_preferences = Registration::UserRegistrations::PreferencesHandler
                          .new.add(item_id, params[:preferences_json])

      render partial: "registration/main/preferences_table",
             locals: { item_preferences: @item_preferences, campaign: @campaign }
    end

    def reset_preferences
      init_preferences
      render partial: "registration/main/preferences_table",
             locals: { item_preferences: @item_preferences, campaign: @campaign }
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
      end

      def init_result
        # TODO: Pull final allocation results from rosterable.roster_entries (tutorial_memberships).
        # TODO: Determine the successful item using roster data instead of confirmed registrations.
        @item_succeed = @campaign.registration_items
                                 .includes(:user_registrations)
                                 .where(user_registrations: { status: :confirmed })
                                 .first
        @items_selected = @campaign.registration_items
                                   .includes(:user_registrations)
                                   .where.not(user_registrations: { id: nil })
        @status_items_selected = @items_selected.index_with do |i|
          UserRegistration.where(registration_campaign_id: @campaign.id, user_id: current_user.id,
                                 registration_item_id: i.id).first&.status
        end
        @campaignable_host = @campaign.campaignable
      end

      def init_preferences
        @user_registrations = @campaign.user_registrations
                                       .where(user_id: current_user.id)
                                       .where(status: [:confirmed, :pending])
        @item_preferences = @user_registrations.includes(:registration_items)
                                               .map(&:registration_items)
                                               .flatten
                                               .map do |item|
          TempItemPreference.new(item,
                                 item.preference_rank(current_user))
        end
      end
  end
end
