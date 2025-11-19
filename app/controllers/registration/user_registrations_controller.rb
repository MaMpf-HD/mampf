module Registration
  class UserRegistrationsController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

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

    def update
      # Update registration logic goes here
    end

    def destroy
      user_registration = UserRegistration.find(id)
      user_registration.destroy
      render json: { message: "Registration cancelled successfully" }, status: :ok
    end

    def render_not_found(exception)
      render json: { error: exception.message }, status: :unprocessable_entity
    end

    private

      def register_user_for_first_come_first_serve(campaign, item)
        # Same campaign, same user -> only 1 registration, regardless of item
        user_registered = check_user_register_selected_campaign_fcfs(campaign, current_user)
        if user_registered
          render json: { error: "User has already registered for this campaign" }, 
                 status: :unprocessable_entity
          return
        end

        # only register if item has remaining capacity
        unless check_item_remaining_capacity(item)
          render json: { error: "Selected item has no remaining capacity" }, 
                 status: :unprocessable_entity
          return
        end

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
