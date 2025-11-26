module Registration
  class UserRegistrationsController < ApplicationController
    # This class handles student registrations for registration campaigns.
    # Although its name is UserRegistrations, but it isn’t just CRUD for UserRegistration model
    # It orchestrates the entire registration process from student perspective.
    #
    # In FCFS mode, students register per item
    # -> create action per item registration + destroy action for deregistration
    #
    # In preference-based mode, students register by batch of selected items
    # -> update action for batch registration + deregistration

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    helper UserRegistrationsHelper

    def index
      render template: "registration/index", layout: "application_no_sidebar"
    end

    def random_campaign
      lecture1 = Lecture.find(1)
      lecture1.capacity = 100
      lecture1.save!

      campaign1 = Campaign.new(
        title: "Lecture Enrollment",
        campaignable_type: "Lecture",
        allocation_mode: 0,
        campaignable_id: 1,
        status: 1,
        registration_deadline: 7.days.from_now
      )
      campaign1.save!
      item1 = Item.new(
        registration_campaign_id: campaign1.id,
        registerable_type: "Lecture",
        registerable_id: 1
      )
      item1.save!

      tutorrial1 = Tutorial.find(1)
      tutorrial1.capacity = 30
      tutorrial1.save!
      tutorrial2 = Tutorial.find(2)
      tutorrial2.capacity = 30
      tutorrial2.save!

      campaign2 = Campaign.new(
        title: "Tutorial Enrollment",
        campaignable_type: "Lecture",
        allocation_mode: 0,
        campaignable_id: 1,
        status: 1,
        registration_deadline: 7.days.from_now
      )
      campaign2.save!
      item21 = Item.new(
        registration_campaign_id: campaign2.id,
        registerable_type: "Tutorial",
        registerable_id: 1
      )
      item21.save!
      item22 = Item.new(
        registration_campaign_id: campaign2.id,
        registerable_type: "Tutorial",
        registerable_id: 2
      )
      item22.save!
    end

    # Get campaigns info + registrations info for current user
    # Not allow draft campaign
    def registrations_for_campaign
      @campaign = Campaign.find(params[:campaign_id])
      if (campaign[:status] == Campaign.status[:draft])
        redirect_to user_registrations_index_path, notice: t('registration.messages.campaign_unavailable')
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
      @campaignable_host = UserRegistrationsHelper.get_campaignable_poro(@campaign.campaignable)
      render template: "registration/main/show_main_campaign", layout: "application_no_sidebar"
    end

    def create
      @item = Item.find(params[:item_id])
      @campaign = Campaign.find(params[:campaign_id])
      if @campaign.campaignable_type == "Lecture" #TODO: compare campaignable type here with lecturer mode
        create_registration_lecture_campaign
      elsif @campaign.campaignable_type == "Exam" #TODO: compare campaignable type here with lecturer mode
        raise(NotImplementedError, "Exam campaignable_type not supported yet")
      end
    end

    def create_registration_lecture_campaign
      if @campaign.allocation_mode == Campaign.allocation_modes[:preference_based]
        raise(NotImplementedError, "Preference-based allocation is not implemented yet")
      else
        register_user_for_first_come_first_serve(@campaign, @item)
      end
    end

    def register_user_for_first_come_first_serve(campaign, item)
      ActiveRecord::Base.transaction do
        item.lock!

        # error redirect if any validation fails
        if (redirect = validate_create_registration(campaign, item, current_user))
          return redirect
        end

        # if all validations pass, create the registration with status confirmed
        @user_registration = UserRegistration.new(
          registration_campaign_id: campaign.id,
          registration_item_id: item.id,
          user_id: current_user.id,
          status: :confirmed
        )
        if @user_registration.save
          redirect_to campaign_registrations_for_campaign_path(campaign_id: campaign.id),
                      notice: t('registration.messages.registration_success')
        else
          redirect_to campaign_registrations_for_campaign_path(campaign_id: campaign.id),
                      alert: t('registration.messages.registration_failed')
        end
      end
    end

    # Validation for creating registration in lecture based registration
    # 0. Check open for registration
    # 1. Check if user has already registered for this campaign
    # 2. Check if item still has capacity
    # 3. Check if user satisfies all policies (registration and both)
    def validate_create_registration(campaign, item, user)
      if campaign.open_for_registrations? == false
        return redirect_to_campaign_with_message(campaign.id, t('registration.messages.campaign_not_opened')

      if user_has_confirmed_registration_selected_campaign?(campaign, user)
        return redirect_to_campaign_with_message(campaign.id,
                                                  t('registration.messages.already_registered'))
      end

      unless item.still_have_capacity?
        return redirect_to_campaign_with_message(campaign.id, t('registration.messages.no_slots'))
      end

      unless [campaign.policies_satisfied?(user, phase: :registration),
              campaign.policies_satisfied?(user, phase: :both)].all?
        return redirect_to_campaign_with_message(campaign.id,
                                                  t('registration.messages.requirements_not_met'))
      end

      nil
    end

    def destroy
      @item = Item.find(params[:item_id])
      @user_registration = @item.user_registrations.find_by!(user_id: current_user.id,
                                                             status: :confirmed)
      @campaign = @user_registration.registration_campaign

      # error redirect if any validation fails
      if (redirect = validate_widthdraw_registration(campaign, item, current_user))
        return redirect
      end

      @user_registration.destroy
      redirect_to campaign_registrations_for_campaign_path(campaign_id: @campaign.id),
                  notice: t('registration.messages.withdrawn')
    end

    # Validation for widthdrawing registration in lecture based registration
    # 0. Check open for registration
    def validate_widthdraw_registration(campaign, item, user)
      if campaign.open_for_registrations? == false
        return redirect_to_campaign_with_message(campaign.id, t('registration.messages.campaign_not_opened')

      nil
    end

    def render_not_found(exception)
      # TODO: redirect to dashboard, and maybe also with error message
      render json: { error: exception.message }, status: :unprocessable_entity
    end

    def redirect_to_campaign_with_message(campaign_id, message)
      redirect_to campaign_registrations_for_campaign_path(campaign_id: campaign_id),
                  notice: message
    end

    private

      def user_has_confirmed_registration_selected_campaign?(campaign, user)
        exist_regist = UserRegistration.find_by(registration_campaign_id: campaign.id,
                                                user_id: user.id)
        exist_regist.present? && exist_regist.status == UserRegistration.statuses[:confirmed]
      end

      def get_eligibility(campaign, phase: :registration)
        eligibility = PolicyEngine.new(campaign).full_trace_with_config_for(current_user,
                                                                            phase: phase)
        eligibility.each do |policy|
          next unless policy.kind == "prerequisite_campaign"

          prereq_campaign_id = policy.config[:prerequisite_campaign_id]
          prereq_campaign = Campaign.find_by(id: prereq_campaign_id)
          if prereq_campaign
            policy.config["prerequisite_campaign_info"] =
              UserRegistrationsHelper.get_campaignable_poro(prereq_campaign.campaignable)
          end
        end
        eligibility
      end
  end
end
