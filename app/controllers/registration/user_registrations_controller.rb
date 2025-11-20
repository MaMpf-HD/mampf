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

    def show
      @registration_campaign = Campaign.find(params[:campaign_id])
      @eligibility = @registration_campaign.evaluate_policies_for(current_user,
                                                                  phase: :certification)
      @items = @registration_campaign.registration_items.includes(:user_registrations)

      if @registration_campaign.allocation_mode == Campaign.allocation_modes[:preference_based]
        render :show_preference_based
      else
        render :show_first_come_first_serve
      end
    end

    def create
      campaign = Campaign.find(params[:campaign_id])
      item = Item.find(params[:item_id])
      allocation_mode = campaign.allocation_mode

      if allocation_mode == Campaign.allocation_modes[:preference_based]
        raise(NotImplementedError, "Preference-based allocation is not implemented yet")
      else
        register_user_for_first_come_first_serve(campaign, item)
      end
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

      def register_user_for_first_come_first_serve(campaign, item)
        @user_registered = check_user_register_selected_campaign_fcfs(campaign, current_user)
        # if user_registered -> error

        @slot_availbled = check_item_remaining_capacity(item)
        # if !slot_available -> error

        @policies_satisfied = campaign.policies_satisfied?(current_user, phase: :registration)
        #if !policies_satisfied -> error

        @user_registration = UserRegistration.new(
          registration_campaign_id: campaign.id,
          registration_item_id: item.id,
          user_id: current_user.id,
          status: :confirmed
        )
        @user_registration.save

      end

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
  end
end
