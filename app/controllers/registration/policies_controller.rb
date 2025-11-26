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
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign, anchor: "policies-tab"),
                        notice: t("registration.policy.created")
          end
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("policy_form",
                                   partial: "registration/policies/empty_form"),
              turbo_stream.replace("policies_list",
                                   partial: "registration/policies/list",
                                   locals: { campaign: @campaign })
            ]
          end
        end
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @policy.update(policy_params)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign, anchor: "policies-tab"),
                        notice: t("registration.policy.updated")
          end
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("policy_form",
                                   partial: "registration/policies/empty_form"),
              turbo_stream.replace("policies_list",
                                   partial: "registration/policies/list",
                                   locals: { campaign: @campaign })
            ]
          end
        end
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @policy.destroy
      redirect_to registration_campaign_path(@campaign, anchor: "policies-tab"),
                  notice: t("registration.policy.destroyed")
    end

    private

      def set_campaign
        @campaign = Registration::Campaign.find(params[:registration_campaign_id])
      end

      def set_policy
        @policy = @campaign.registration_policies.find(params[:id])
      end

      def policy_params
        params.expect(registration_policy: [:kind, :phase, :position, { config: {} }])
      end

      def current_ability
        @current_ability ||= CampaignAbility.new(current_user)
      end
  end
end
