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
      render template: "registration/index", layout: "application_no_sidebar"
    end

    # Get campaigns info + registrations info for current user
    # Not allow draft campaign
    def registrations_for_campaign
      @campaign = Registration::Campaign.find(params[:campaign_id])
      if @campaign.draft?
        return redirect_to user_registrations_path,
                           notice: I18n.t("registration.messages.campaign_unavailable")
      end
      if @campaign.campaignable_type == "Lecture"
        show_campaign_host_by_lecture
      elsif @campaign.campaignable_type == "Exam"
        raise(NotImplementedError, "Exam campaignable_type not supported yet")
      else
        raise(NotImplementedError, "Unsupported campaignable_type")
      end
    end

    def show_campaign_host_by_lecture
      @eligibility = get_eligibility(@campaign)
      @items = @campaign.registration_items.includes(:user_registrations)
      @campaignable_host = @campaign.campaignable
      render template: "registration/main/show_main_campaign", layout: "application_no_sidebar"
    end

    def create
      @item = Registration::Item.find(params[:item_id])
      @campaign = Registration::Campaign.find(params[:campaign_id])

      if @campaign.campaignable_type == "Lecture"
        raise(NotImplementedError) unless @campaign.first_come_first_served?

        # TODO: compare campaignable type here with lecturer mode
        begin
          Registration::LectureFcfsService.new(@campaign, @item, current_user).register!
          redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                      success: I18n.t("registration.messages.registration_success")
        rescue Registration::RegistrationError => e
          redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                      alert: e.message.to_s
        end

      elsif @campaign.campaignable_type == "Exam"
        # TODO: compare campaignable type here with lecturer mode
        raise(NotImplementedError, "Exam campaignable_type not supported yet")
      end
    end

    def destroy
      @item = Registration::Item.find(params[:item_id])
      @user_registration = @item.user_registrations.find_by!(user_id: current_user.id,
                                                             status: :confirmed)
      @campaign = @user_registration.registration_campaign

      if @campaign.campaignable_type == "Lecture"
        # TODO: compare campaignable type here with lecturer mode
        case @campaign.allocation_mode.to_sym
        when :first_come_first_served
          begin
            Registration::LectureFcfsService.new(@campaign, @item, current_user).withdraw!
            redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                        success: I18n.t("registration.messages.withdrawn")
          rescue Registration::RegistrationError => e
            redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                        alert: e.message.to_s
          end
        else
          raise(NotImplementedError)
        end
      elsif @campaign.campaignable_type == "Exam"
        # TODO: compare campaignable type here with lecturer mode
        raise(NotImplementedError, "Exam campaignable_type not supported yet")
      end
    end

    def render_not_found(exception)
      render json: { error: exception.message }, status: :unprocessable_content
    end

    private

      def get_eligibility(campaign, phase: :registration)
        eligibility = PolicyEngine.new(campaign).full_trace_with_config_for(current_user,
                                                                            phase: phase)
        eligibility.each do |policy_trace|
          next unless policy_trace[:kind] == "prerequisite_campaign"

          prereq_campaign_id = policy_trace[:config][:prerequisite_campaign_id]
          prereq_campaign = Registration::Campaign.find_by(id: prereq_campaign_id)
          policy_trace[:config]["prerequisite_campaign_info"] = "TODO" if prereq_campaign
        end
        eligibility
      end
  end
end
