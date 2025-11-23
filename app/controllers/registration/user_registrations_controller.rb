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
      render template: "registration/student/index", layout: "application"
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

    def show
      @campaign = Campaign.find(params[:id])
      if @campaign.campaignable_type == "Lecture"
        show_campaign_host_by_lecture
      elsif @campaign.campaignable_type == "Exam"
        show_campaign_host_by_exam
      else
        raise(NotImplementedError, "Unsupported campaignable_type")
      end
    end

    def show_campaign_host_by_lecture
      @eligibility = get_eligibility(@campaign)
      @items = @campaign.registration_items.includes(:user_registrations)
      @campaignable_host = get_campaignable_host(@campaign)
      render template: "registration/student/show", layout: "application"
    end

    def show_campaign_host_by_exam
      raise(NotImplementedError, "Exam campaignable_type not supported yet")
    end

    def create
      @item = Item.find(params[:item_id])
      @campaign = Campaign.find(params[:campaign_id])
      allocation_mode = @campaign.allocation_mode

      if allocation_mode == Campaign.allocation_modes[:preference_based]
        raise(NotImplementedError, "Preference-based allocation is not implemented yet")
      end

      register_user_for_first_come_first_serve(@campaign, @item)

      @items = @campaign.registration_items.includes(:user_registrations)
      @campaignable_host = get_campaignable_host(@campaign)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "items_frame",
            partial: "registration/student/select_fcfs",
            locals: {
              campaign: @campaign,
              campaignable_host: @campaignable_host,
              items: @items
            }
          )
        end
      end
    end

    def register_user_for_first_come_first_serve(campaign, item)
      ActiveRecord::Base.transaction do
        item.lock!

        user_registered = user_has_confirmed_registration_selected_campaign(campaign, current_user)
        # if user_registered -> error

        slot_availbled = item.still_have_capacity?
        # if !slot_available -> error

        # TODO: check policies and phase
        policies_satisfied = campaign.policies_satisfied?(current_user, phase: :registration)
        # if !policies_satisfied -> error

        @user_registration = UserRegistration.new(
          registration_campaign_id: campaign.id,
          registration_item_id: item.id,
          user_id: current_user.id,
          status: :confirmed
        )
        @user_registration.save
      end
    end

    def destroy
      @campaign = Campaign.find(params[:campaign_id])
      @item = Item.find(params[:item_id])
      @items = @campaign.registration_items.includes(:user_registrations)
      @campaignable_host = get_campaignable_host(@campaign)

      user_registration = @item.user_registrations.find_by!(user_id: current_user.id,
                                                            status: :confirmed)

      user_registration.destroy if user_registration.present?

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "items_frame",
            partial: "registration/student/select_fcfs",
            locals: {
              campaign: @campaign,
              campaignable_host: @campaignable_host,
              items: @items
            }
          )
        end
      end
    end

    def render_not_found(exception)
      render json: { error: exception.message }, status: :unprocessable_entity
    end

    private

      def user_has_confirmed_registration_selected_campaign(campaign, user)
        exist_regist = UserRegistration.find_by(registration_campaign_id: campaign.id,
                                                user_id: user.id)
        exist_regist.present? && exist_regist.status == UserRegistration.statuses[:confirmed]
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

      # lecture_performance and institutional_email policies has cleared info in config
      # optional: prerequisite_campaign can have additional check for name of prerequisite campaign
      def get_eligibility(campaign, phase: :registration)
        eligibility = PolicyEngine.new(campaign).full_trace_with_config_for(current_user,
                                                                            phase: phase)
        eligibility.each do |policy|
          next unless policy.kind == "prerequisite_campaign"

          prereq_campaign_id = policy.config[:prerequisite_campaign_id]
          prereq_campaign = Campaign.find_by(id: prereq_campaign_id)
          if prereq_campaign
            policy.config["prerequisite_campaign_info"] = get_campaignable_host(prereq_campaign)
          end
        end
        eligibility
      end
  end
end
