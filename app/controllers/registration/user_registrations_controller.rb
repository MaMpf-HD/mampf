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

    helper UserRegistrationsHelper

    def index
      render template: "registration/index", layout: "application_no_sidebar"
    end

    def random_campaign
      lecture1 = Lecture.find(1)
      lecture1.capacity = 100
      lecture1.save!

      campaign_lecture = Registration::Campaign.new(
        title: "Lecture Enrollment",
        campaignable_type: "Lecture",
        allocation_mode: 0,
        campaignable_id: 1,
        status: 1,
        registration_deadline: 7.days.from_now
      )
      campaign_lecture.save!
      item_lecture = Registration::Item.new(
        registration_campaign_id: campaign_lecture.id,
        registerable_type: "Lecture",
        registerable_id: 1
      )
      item_lecture.save!

      # Notice that 1 type
      # campaign_lecture_planning = Registration::Campaign.new(
      #   title: "Lecture Enrollment",
      #   campaignable_type: "Lecture",
      #   allocation_mode: 0,
      #   campaignable_id: 1,
      #   status: 1,
      #   registration_deadline: 7.days.from_now,
      #   planning_only: true
      # )
      # campaign_lecture.save!
      # item_lecture_planning = Registration::Item.new(
      #   registration_campaign_id: campaign_lecture_planning.id,
      #   registerable_type: "Lecture",
      #   registerable_id: 1
      # )
      # item_lecture_planning.save!

      tutorial1 = Tutorial.find(1)
      tutorial1.capacity = 30
      tutorial1.save!

      tutorial2 = Tutorial.find(2)
      if tutorial2.nil?
        tutorial2 = Tutorial.new(
          title: "Di 14-19",
          lecture: lecture1,
          capacity: 60
        )
        tutorial2.save!
      else
        tutorial2.capacity = 60
        tutorial2.save!
      end

      campaign_tutorial = Registration::Campaign.new(
        title: "Tutorial Enrollment",
        campaignable_type: "Lecture",
        allocation_mode: 0,
        campaignable_id: 1,
        status: 1,
        registration_deadline: 7.days.from_now
      )
      campaign_tutorial.save!
      item21 = Registration::Item.new(
        registration_campaign_id: campaign_tutorial.id,
        registerable_type: "Tutorial",
        registerable_id: tutorial1.id
      )
      item21.save!
      item22 = Registration::Item.new(
        registration_campaign_id: campaign_tutorial.id,
        registerable_type: "Tutorial",
        registerable_id: tutorial2.id
      )
      item22.save!
      policy_email = Registration::Policy.new(
        registration_campaign_id: campaign_tutorial.id,
        kind: :institutional_email,
        phase: :registration,
        config: { allowed_domains: ["mampf.edu"] },
        position: 1,
        active: true
      )
      policy_email.save!
      policy_prereq = Registration::Policy.new(
        registration_campaign_id: campaign_tutorial.id,
        kind: :prerequisite_campaign,
        phase: :registration,
        config: { prerequisite_campaign_id: campaign_lecture.id },
        position: 3,
        active: true
      )
      policy_prereq.save!
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
