module Registration
  class PoliciesController < ApplicationController
    before_action :set_campaign
    before_action :set_policy, only: [:edit, :update, :destroy]
    authorize_resource class: "Registration::Policy"

    def new
      @policy = @campaign.registration_policies.build
    end

    def edit
    end

    def create
      @policy = @campaign.registration_policies.build(policy_params)
      if @policy.save
        redirect_to registration_campaign_path(@campaign), notice: t("registration.policy.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @policy.update(policy_params)
        redirect_to registration_campaign_path(@campaign), notice: t("registration.policy.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @policy.destroy
      redirect_to registration_campaign_path(@campaign), notice: t("registration.policy.destroyed")
    end

    private

      def set_campaign
        @campaign = Registration::Campaign.find(params[:campaign_id])
      end

      def set_policy
        @policy = @campaign.registration_policies.find(params[:id])
      end

      def policy_params
        params.require(:registration_policy).permit(:kind, :phase, :position, config: {})
      end

      def current_ability
        @current_ability ||= CampaignAbility.new(current_user)
      end
  end
end
