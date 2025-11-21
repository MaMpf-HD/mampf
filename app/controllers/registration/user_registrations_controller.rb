module Registration
  class UserRegistrationsController < ApplicationController
    # This class handles student registrations for registration campaigns.
    # Although its name is UserRegistrations, but isn’t just CRUD for UserRegistration.
    # It’s orchestrating the entire registration process
    #
    # In FCFS mode, students register item by item
    # -> create action per item registration + destroy action for deregistration
    # In preference-based mode, students register by batch
    # -> update action for batch registration + deregistration

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    def index
      render template: "registration/student/index", layout: "application"
    end

    def random_campaign
      campaign1 = Campaign.new(
        title: "Lecture Enrollment",
        campaignable_type: "Lecture",
        allocation_mode: 0,
        campaignable_id: 1,
        status: 1,
        registration_deadline: 7.days.from_now
      )
      campaign1.save!
      item = Item.new(
        registration_campaign_id: campaign1.id,
        registerable_type: "Lecture",
        registerable_id: 1
      )
      item.save!
    end

    def show
      @registration_campaign = Campaign.find(params[:id])
      if @registration_campaign.campaignable_type == "Lecture"
        show_campaign_host_by_lecture
      elsif @registration_campaign.campaignable_type == "Exam"
        show_campaign_host_by_exam
      else
        raise(NotImplementedError, "Unsupported campaignable_type")
      end
    end

    def show_campaign_host_by_lecture
      @eligibility = @registration_campaign.evaluate_policies_for(current_user,
                                                                  phase: :certification)
      @items = @registration_campaign.registration_items.includes(:user_registrations)
      @campaignable_host = get_campaignable_host(@registration_campaign)
      render template: "registration/student/show", layout: "application"
    end

    def show_campaign_host_by_exam
      raise(NotImplementedError, "Exam campaignable_type not supported yet")
    end

    def create
      campaign = Campaign.find(params[:campaign_id])
      item = Item.find(params[:item_id])
      allocation_mode = campaign.allocation_mode

      if allocation_mode == Campaign.allocation_modes[:preference_based]
        raise(NotImplementedError, "Preference-based allocation is not implemented yet")
      end

      register_user_for_first_come_first_serve(campaign, item)
    end

    def register_user_for_first_come_first_serve(campaign, item)
      @user_registered = check_user_register_selected_campaign_fcfs(campaign, current_user)
      # if user_registered -> error

      @slot_availbled = check_item_remaining_capacity(item)
      # if !slot_available -> error

      @policies_satisfied = campaign.policies_satisfied?(current_user, phase: :registration)
      # if !policies_satisfied -> error

      @user_registration = UserRegistration.new(
        registration_campaign_id: campaign.id,
        registration_item_id: item.id,
        user_id: current_user.id,
        status: :confirmed
      )
      @user_registration.save
    end

    def destroy
      user_registration = UserRegistration.find(params[:id])
      user_registration.destroy
      # -> update status and then update action
    end

    def render_not_found(exception)
      render json: { error: exception.message }, status: :unprocessable_entity
    end

    private

      def check_user_register_selected_campaign_fcfs(campaign, user)
        exist_regist = UserRegistration.find_by(registration_campaign_id: campaign.id,
                                                user_id: user.id)
        exist_regist.present?
      end

      def check_item_remaining_capacity(item)
        total_capacity = item.capacity
        confirmed_registrations_count = item.user_registrations.where(status: :confirmed).count
        remaining_capacity = total_capacity - confirmed_registrations_count
        remaining_capacity.positive?
      end

      def get_campaignable_host(campaign)
        host = campaign.campaignable
        Registration::CampaignablePoro.new(
          id: host.id,
          title: host.course.title,
          term_year: host.term.year,
          term_season: host.term.season,
          course_short_title: host.course.short_title
        )
      end
  end
end
