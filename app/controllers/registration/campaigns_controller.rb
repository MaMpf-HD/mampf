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
          render_card_body("registration/campaigns/card_body_index", lecture: @lecture)
        end
      end
    end

    def show
      respond_to do |format|
        format.html
        format.turbo_stream do
          render_card_body("registration/campaigns/card_body_show", campaign: @campaign)
        end
      end
    end

    def new
      @campaign = @lecture.registration_campaigns.build
      authorize! :new, @campaign

      respond_to do |format|
        format.html
        format.turbo_stream do
          render_card_body("registration/campaigns/card_body_form",
                           campaign: @campaign, lecture: @lecture)
        end
      end
    end

    def edit
      respond_to do |format|
        format.html
        format.turbo_stream do
          render_card_body("registration/campaigns/card_body_form",
                           campaign: @campaign, lecture: @campaign.campaignable)
        end
      end
    end

    def create
      @campaign = @lecture.registration_campaigns.build(campaign_params)
      authorize! :create, @campaign

      if @campaign.save
        respond_with_success(t("registration.campaign.created"))
      else
        respond_with_form_error(t("registration.campaign.create_failed"), :new)
      end
    end

    def update
      if @campaign.update(campaign_params)
        respond_with_success(t("registration.campaign.updated"))
      else
        respond_with_form_error(t("registration.campaign.update_failed"), :edit)
      end
    end

    def destroy
      unless @campaign.can_be_deleted?
        respond_with_error(t("registration.campaign.cannot_delete"))
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
          ].compact
        end
      end
    end

    def open
      update_status(:open, t("registration.campaign.opened"))
    end

    def close
      update_status(:closed, t("registration.campaign.closed"))
    end

    def reopen
      update_status(:open, t("registration.campaign.reopened"))
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

      def update_status(status, success_message)
        if @campaign.update(status: status)
          respond_with_success(success_message)
        else
          respond_with_error(@campaign.errors.full_messages.join(", "))
        end
      end

      def render_card_body(partial, locals)
        render turbo_stream: turbo_stream.replace("campaigns_card_body",
                                                  partial: partial,
                                                  locals: locals)
      end

      def respond_with_success(message)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign), notice: message
          end
          format.turbo_stream do
            flash.now[:notice] = message
            render turbo_stream: [
              turbo_stream.replace("campaigns_card_body",
                                   partial: "registration/campaigns/card_body_show",
                                   locals: { campaign: @campaign }),
              stream_flash
            ].compact
          end
        end
      end

      def respond_with_form_error(message, action)
        respond_to do |format|
          format.html { render action, status: :unprocessable_content }
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: [
              turbo_stream.replace("campaigns_card_body",
                                   partial: "registration/campaigns/card_body_form",
                                   locals: { campaign: @campaign,
                                             lecture: @campaign.campaignable }),
              stream_flash
            ].compact
          end
        end
      end

      def respond_with_error(message)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign), alert: message
          end
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: stream_flash
          end
        end
      end
  end
end
