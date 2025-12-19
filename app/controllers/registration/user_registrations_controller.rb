module Registration
  class UserRegistrationsController < ApplicationController
    # This class handles student registrations for registration campaigns.
    #
    # In FCFS mode, students register per item
    # -> create action per item registration + destroy action for deregistration
    # In preference-based mode, students register by batch of selected items
    # -> update action for batch registration + deregistration
    #
    # In Exam registration
    # -> likely the same as FCFS single mode

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    helper UserRegistrationsHelper
    before_action :set_locale
    PreferenceItem = Struct.new(:id, :preference_rank)

    TempItemPreference = Struct.new(:item, :temp_preference_rank)

    def index
      @courses_seminars_campaigns = Registration::Campaign.all
      @eligibilities = @courses_seminars_campaigns.index_with do |c|
        Registration::EligibilityService.new(c, current_user,
                                             phase_scope: :registration).call
      end
      render template: "registration/index", layout: "application_no_sidebar"
    end

    # Get campaigns info + registrations info for current user
    def registrations_for_campaign
      @campaign = Registration::Campaign.find(params[:campaign_id])

      target = resolve_render_target(@campaign)
      case target
      when :lecture_index, :exam_index
        redirect_to user_registrations_path,
                    notice: I18n.t("registration.messages.campaign_unavailable")
      when :lecture_details
        init_details
        init_preferences if @campaign.preference_based?
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

    def init_details
      @eligibility = Registration::EligibilityService.new(@campaign, current_user,
                                                          phase_scope: :registration).call
      @items = @campaign.registration_items.includes(:user_registrations)
      @campaignable_host = @campaign.campaignable
    end

    def init_result
      # TODO: in future: get roster result from rosterable.roster_entries -> tutorial_memberships
      # TODO; retrieve item succeed from roster
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
      reset_preferences
      @user_registrations = @campaign.user_registrations
                                     .where(user_id: current_user.id)
                                     .where(status: [:confirmed, :pending])

      item_preferences = @user_registrations.includes(:registration_items)
                                            .map(&:registration_items)
                                            .flatten
      @item_preferences = item_preferences.map do |item|
        TempItemPreference.new(item, item.preference_rank(current_user))
      end
    end

    def create
      @item = Registration::Item.find(params[:item_id])
      @campaign = Registration::Campaign.find(params[:campaign_id])

      if @campaign.campaignable_type == "Lecture"
        case @campaign.allocation_mode.to_sym
        when :first_come_first_served
          result = Registration::UserRegistration::LectureFcfsEditService
                   .new(@campaign, current_user, @item).register!

          if result.success?
            redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                        success: I18n.t("registration.messages.registration_success")
          else
            redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                        alert: result.errors.join(", ")
          end
        else
          raise(NotImplementedError)
        end

      elsif @campaign.campaignable_type == "Exam"
        raise(NotImplementedError, "Exam campaignable_type not supported yet")
      end
    end

    def destroy
      @item = Registration::Item.find(params[:item_id])
      @user_registration = @item.user_registrations.find_by!(user_id: current_user.id,
                                                             status: :confirmed)
      @campaign = @user_registration.registration_campaign

      if @campaign.campaignable_type == "Lecture"
        case @campaign.allocation_mode.to_sym
        when :first_come_first_served
          result = Registration::UserRegistration::LectureFcfsEditService
                   .new(@campaign, current_user, @item).withdraw!

          if result.success?
            redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                        success: I18n.t("registration.messages.withdrawn")
          else
            redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                        alert: result.errors.join(", ")
          end
        else
          raise(NotImplementedError)
        end
      elsif @campaign.campaignable_type == "Exam"
        raise(NotImplementedError, "Exam campaignable_type not supported yet")
      end
    end

    def render_not_found(exception)
      render json: { error: exception.message }, status: :unprocessable_content
    end

    def up
      item_id = params[:item_id].to_i
      item = Registration::Item.find(item_id)
      preferences_store = JSON.parse(params[:preferences_json]) || []
      preferences_store = preferences_store.map do |item_hash|
        { "id" => item_hash["item"]["id"].to_i,
          "preference_rank" => item_hash["temp_preference_rank"].to_i }
      end
      pref_item = preferences_store.map do |item_hash|
        PreferenceItem.new(item_hash["id"], item_hash["preference_rank"])
      end

      temp_item = pref_item.find { |i| i.id == item_id }
      temp_item_above = pref_item.find { |i| i.preference_rank == temp_item.preference_rank - 1 }
      if temp_item && temp_item_above
        temp_item.preference_rank -= 1
        temp_item_above.preference_rank += 1
      end
      data = pref_item.map { |i| i.to_h.stringify_keys }
      compute_preferences_from_preferences_store(data)
      @campaign = item.registration_campaign

      render partial: "registration/main/preferences_table",
             locals: { item_preferences: @item_preferences, campaign: @campaign }
    end

    def down
      item_id = params[:item_id].to_i
      item = Registration::Item.find(item_id)
      preferences_store = JSON.parse(params[:preferences_json]) || []
      preferences_store = preferences_store.map do |item_hash|
        { "id" => item_hash["item"]["id"].to_i,
          "preference_rank" => item_hash["temp_preference_rank"].to_i }
      end
      pref_item = preferences_store.map do |item_hash|
        PreferenceItem.new(item_hash["id"], item_hash["preference_rank"])
      end
      temp_item = pref_item.find { |i| i.id == item_id }
      temp_item_below = pref_item.find { |i| i.preference_rank == temp_item.preference_rank + 1 }
      if temp_item && temp_item_below
        temp_item.preference_rank += 1
        temp_item_below.preference_rank -= 1
      end
      data = pref_item.map { |i| i.to_h.stringify_keys }
      compute_preferences_from_preferences_store(data)
      @campaign = item.registration_campaign

      render partial: "registration/main/preferences_table",
             locals: { item_preferences: @item_preferences, campaign: @campaign }
    end

    def add
      t = params
      item_id = params[:item_id]
      item = Registration::Item.find(item_id)
      preferences_store = JSON.parse(params[:preferences_json]) || []
      preferences_store = preferences_store.map do |item_hash|
        { "id" => item_hash["item"]["id"].to_i,
          "preference_rank" => item_hash["temp_preference_rank"].to_i }
      end
      unless preferences_store.any? { |i| i["id"].to_i == item_id.to_i }
        preferences_store << { "id" => item_id.to_i,
                               "preference_rank" => preferences_store.size + 1 }
      end
      compute_preferences_from_preferences_store(preferences_store)
      @campaign = item.registration_campaign

      render partial: "registration/main/preferences_table",
             locals: { item_preferences: @item_preferences, campaign: @campaign }
    end

    def compute_preferences_from_session
      @preferences_short = data
      preferences = preferences_hash.sort_by { |h| h["preference_rank"] }
                                    .map { |item_hash| Registration::Item.find(item_hash["id"].to_i) }
      @item_preferences = preferences.filter { |item| item.nil? == false }
    end

    def compute_preferences_from_preferences_store(preferences_store)
      preferences_store_sorted = preferences_store.sort_by { |h| h["preference_rank"] }
      @item_preferences = preferences_store_sorted.map do |item_hash|
        item = Registration::Item.find(item_hash["id"].to_i)
        TempItemPreference.new(item, item_hash["preference_rank"])
      end
    end

    def reset_preferences
      # session[:preferences] = []

      # # update by turbo frame
    end

    # def save_preferences
    #   preferences_hash = session[:preferences]
    #   preferences = preferences_hash.map do |item_hash|
    #     PreferenceItem.new(item_hash["id"], item_hash["preference_rank"])
    #   end
    #   @campaign = Registration::Campaign.find(params[:campaign_id])
    #   if @campaign.campaignable_type == "Lecture"
    #     result = Registration::UserRegistration::LecturePreferenceEditService
    #              .new(@campaign, current_user, preferences).update_preferences!
    #     if result.success?

    private

      def resolve_render_target(campaign)
        case campaign.status.to_sym
        when :draft
          @campaign.campaignable_type == "Lecture" ? :lecture_index : :exam_index
        when :open, :closed, :processing
          @campaign.campaignable_type == "Lecture" ? :lecture_details : :exam_details
        when :completed
          @campaign.campaignable_type == "Lecture" ? :lecture_result : :exam_result
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
  end
end
