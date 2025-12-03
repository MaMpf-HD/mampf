module Registration
  class PoliciesController < ApplicationController
    before_action :set_campaign
    before_action :set_locale
    before_action :set_policy, only: [:edit, :update, :destroy, :move_up, :move_down]
    authorize_resource class: "Registration::Policy"

    def new
      @policy = @campaign.registration_policies.build
    end

    def edit
    end

    def create
      @policy = @campaign.registration_policies.build(policy_params)
      if @policy.save
        respond_with_success(t("registration.policy.created"))
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @policy.update(policy_params)
        respond_with_success(t("registration.policy.updated"))
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @policy.destroy
      respond_with_success(t("registration.policy.destroyed"))
    end

    def move_up
      move(:higher)
    end

    def move_down
      move(:lower)
    end

    private

      def set_campaign
        @campaign = Registration::Campaign.find(params[:registration_campaign_id])
      end

      def set_policy
        @policy = @campaign.registration_policies.find(params[:id])
      end

      def set_locale
        I18n.locale = @campaign&.locale_with_inheritance || I18n.locale
      end

      def policy_params
        params.expect(registration_policy: [:kind, :phase, :allowed_domains,
                                            :prerequisite_campaign_id])
      end

      def current_ability
        @current_ability ||= CampaignAbility.new(current_user)
      end

      def move(direction)
        @policy.public_send("move_#{direction}")
        respond_with_success(nil)
      end

      def respond_with_success(message)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign, anchor: "policies-tab"),
                        notice: message
          end
          format.turbo_stream do
            flash.now[:notice] = message if message
            render turbo_stream: [
              turbo_stream.replace("campaigns_card_body",
                                   partial: "registration/campaigns/card_body_show",
                                   locals: { campaign: @campaign, tab: "policies" }),
              stream_flash
            ].compact
          end
        end
      end
  end
end
