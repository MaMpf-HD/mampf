module Registration
  class UserRegistrationsController < ApplicationController
    # This class handles student registrations for registration campaigns.
    #
    # In FCFS mode, students register per item
    # -> create action per item registration + destroy action for deregistration
    #
    # In preference-based mode, students register by batch of selected items
    # -> update action for batch registration + deregistration
    #
    # In Exam registration
    # -> likely the same as FCFS single mode

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    helper UserRegistrationsHelper

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
      # TODO: I think all registerable should be rosterable
      # Manual Roster Maintenance should also update the user registration
      #
      # at completed stage, roster result should also available
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

    def create
      @item = Registration::Item.find(params[:item_id])
      @campaign = Registration::Campaign.find(params[:campaign_id])

      if @campaign.campaignable_type == "Lecture"
        case @campaign.allocation_mode.to_sym
        when :first_come_first_served
          result = Registration::UserRegistration::LectureFcfsEditService.new(@campaign, current_user,
                                                            @item).register!

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
          result = Registration::UserRegistration::LectureFcfsEditService.new(@campaign, current_user,
                                                            @item).withdraw!

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
  end
end
