module Registration
  class CampaignsController < ApplicationController
    before_action :set_lecture, only: [:index, :new, :create]
    before_action :set_campaign, except: [:index, :new, :create]
    before_action :set_locale
    authorize_resource class: "Registration::Campaign", except: [:index, :new, :create]

    def current_ability
      @current_ability ||= CampaignAbility.new(current_user)
    end

    def index
      authorize! :index, Registration::Campaign.new(campaignable: @lecture)
      @campaigns = @lecture.registration_campaigns.order(created_at: :desc)

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream:
          turbo_stream.replace("campaigns_card_body",
                               partial: "registration/campaigns/card_body_index",
                               locals: { lecture: @lecture })
        end
      end
    end

    def show
      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream:
          turbo_stream.replace("campaigns_card_body",
                               partial: "registration/campaigns/card_body_show",
                               locals: { campaign: @campaign })
        end
      end
    end

    def new
      @campaign = @lecture.registration_campaigns.build
      authorize! :new, @campaign

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream:
          turbo_stream.replace("campaigns_card_body",
                               partial: "registration/campaigns/card_body_form",
                               locals: { campaign: @campaign,
                                         lecture: @lecture })
        end
      end
    end

    def edit
      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream:
          turbo_stream.replace("campaigns_card_body",
                               partial: "registration/campaigns/card_body_form",
                               locals: { campaign: @campaign,
                                         lecture: @campaign.campaignable })
        end
      end
    end

    def create
      @campaign = @lecture.registration_campaigns.build(campaign_params)
      authorize! :create, @campaign

      if @campaign.save
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign),
                        notice: t("registration.campaign.created")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.campaign.created")
            render turbo_stream: [
              turbo_stream.replace("campaigns_card_body",
                                   partial: "registration/campaigns/card_body_show",
                                   locals: { campaign: @campaign }),
              stream_flash
            ]
          end
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_content }
          format.turbo_stream do
            flash.now[:alert] = t("registration.campaign.create_failed")
            render turbo_stream: [
              turbo_stream.replace("campaigns_card_body",
                                   partial: "registration/campaigns/card_body_form",
                                   locals: { campaign: @campaign,
                                             lecture: @lecture }),
              stream_flash
            ]
          end
        end
      end
    end

    def update
      if @campaign.update(campaign_params)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign),
                        notice: t("registration.campaign.updated")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.campaign.updated")
            render turbo_stream: [
              turbo_stream.replace("campaigns_card_body",
                                   partial: "registration/campaigns/card_body_show",
                                   locals: { campaign: @campaign }),
              stream_flash
            ]
          end
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_content }
          format.turbo_stream do
            flash.now[:alert] = t("registration.campaign.update_failed")
            render turbo_stream: [
              turbo_stream.replace("campaigns_card_body",
                                   partial: "registration/campaigns/card_body_form",
                                   locals: { campaign: @campaign,
                                             lecture: @campaign.campaignable }),
              stream_flash
            ]
          end
        end
      end
    end

    def destroy
      unless @campaign.can_be_deleted?
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign),
                        alert: t("registration.campaign.cannot_delete")
          end
          format.turbo_stream do
            flash.now[:alert] = t("registration.campaign.cannot_delete")
            render turbo_stream: stream_flash
          end
        end
        return
      end

      lecture = @campaign.campaignable
      @campaign.destroy

      respond_to do |format|
        format.html do
          redirect_to lecture_registration_campaigns_path(lecture),
                      notice: t("registration.campaign.destroyed")
        end
        format.turbo_stream do
          flash.now[:notice] = t("registration.campaign.destroyed")
          render turbo_stream: [
            turbo_stream.replace("campaigns_card_body",
                                 partial: "registration/campaigns/card_body_index",
                                 locals: { lecture: lecture }),
            stream_flash
          ]
        end
      end
    end

    def open
      if @campaign.update(status: :open)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign),
                        notice: t("registration.campaign.opened")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.campaign.opened")
            render turbo_stream: [
              turbo_stream.replace("campaigns_card_body",
                                   partial: "registration/campaigns/card_body_show",
                                   locals: { campaign: @campaign }),
              stream_flash
            ]
          end
        end
      else
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign),
                        alert: @campaign.errors.full_messages.join(", ")
          end
          format.turbo_stream do
            flash.now[:alert] = @campaign.errors.full_messages.join(", ")
            render turbo_stream: stream_flash
          end
        end
      end
    end

    def close
      if @campaign.update(status: :closed)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign),
                        notice: t("registration.campaign.closed")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.campaign.closed")
            render turbo_stream: [
              turbo_stream.replace("campaigns_card_body",
                                   partial: "registration/campaigns/card_body_show",
                                   locals: { campaign: @campaign }),
              stream_flash
            ]
          end
        end
      else
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign),
                        alert: @campaign.errors.full_messages.join(", ")
          end
          format.turbo_stream do
            flash.now[:alert] = @campaign.errors.full_messages.join(", ")
            render turbo_stream: stream_flash
          end
        end
      end
    end

    def reopen
      if @campaign.update(status: :open)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign),
                        notice: t("registration.campaign.reopened")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.campaign.reopened")
            render turbo_stream: [
              turbo_stream.replace("campaigns_card_body",
                                   partial: "registration/campaigns/card_body_show",
                                   locals: { campaign: @campaign }),
              stream_flash
            ]
          end
        end
      else
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign),
                        alert: @campaign.errors.full_messages.join(", ")
          end
          format.turbo_stream do
            flash.now[:alert] = @campaign.errors.full_messages.join(", ")
            render turbo_stream: stream_flash
          end
        end
      end
    end

    private

      def set_lecture
        @lecture = Lecture.find(params[:lecture_id])
      end

      def set_campaign
        @campaign = Registration::Campaign.find(params[:id])
      end

      def set_locale
        I18n.locale = @campaign&.locale_with_inheritance ||
                      @lecture&.locale_with_inheritance ||
                      I18n.locale
      end

      def campaign_params
        params.expect(
          registration_campaign: [:title, :allocation_mode,
                                  :registration_deadline, :planning_only]
        )
      end
  end
end
