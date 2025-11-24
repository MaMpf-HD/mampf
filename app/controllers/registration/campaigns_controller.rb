module Registration
  class CampaignsController < ApplicationController
    before_action :set_lecture, only: [:index, :new, :create]
    before_action :set_campaign, except: [:index, :new, :create]
    authorize_resource class: "Registration::Campaign", except: [:index, :new, :create]

    def current_ability
      @current_ability ||= CampaignAbility.new(current_user)
    end

    def index
      authorize! :index, Registration::Campaign.new(campaignable: @lecture)
      @campaigns = @lecture.registration_campaigns.order(created_at: :desc)
    end

    def show
    end

    def new
      @campaign = @lecture.registration_campaigns.build
      authorize! :new, @campaign
    end

    def edit
    end

    def create
      @campaign = @lecture.registration_campaigns.build(campaign_params)
      authorize! :create, @campaign

      if @campaign.save
        redirect_to registration_campaign_path(@campaign),
                    notice: t("registration.campaign.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @campaign.update(campaign_params)
        redirect_to registration_campaign_path(@campaign),
                    notice: t("registration.campaign.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      unless @campaign.can_be_deleted?
        return redirect_to registration_campaign_path(@campaign),
                           alert: t("registration.campaign.cannot_delete")
      end

      @campaign.destroy
      redirect_to lecture_registration_campaigns_path(@campaign.campaignable),
                  notice: t("registration.campaign.destroyed")
    end

    def open
      if @campaign.update(status: :open)
        redirect_to registration_campaign_path(@campaign),
                    notice: t("registration.campaign.opened")
      else
        redirect_to registration_campaign_path(@campaign),
                    alert: @campaign.errors.full_messages.join(", ")
      end
    end

    def close
      if @campaign.update(status: :closed)
        redirect_to registration_campaign_path(@campaign),
                    notice: t("registration.campaign.closed")
      else
        redirect_to registration_campaign_path(@campaign),
                    alert: @campaign.errors.full_messages.join(", ")
      end
    end

    def reopen
      if @campaign.update(status: :open)
        redirect_to registration_campaign_path(@campaign),
                    notice: t("registration.campaign.reopened")
      else
        redirect_to registration_campaign_path(@campaign),
                    alert: @campaign.errors.full_messages.join(", ")
      end
    end

    private

      def set_lecture
        @lecture = Lecture.find(params[:lecture_id])
      end

      def set_campaign
        @campaign = Registration::Campaign.find(params[:id])
      end

      def campaign_params
        params.expect(
          registration_campaign: [:title, :allocation_mode,
                                  :registration_deadline, :planning_only]
        )
      end
  end
end
