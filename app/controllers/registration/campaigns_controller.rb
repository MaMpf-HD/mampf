module Registration
  class CampaignsController < ApplicationController
    before_action :set_lecture, only: [:index, :new, :create]
    before_action :set_campaign, except: [:index, :new, :create]
    before_action :set_locale
    authorize_resource class: "Registration::Campaign", except: [:index, :new, :create]

    def current_ability
      @current_ability ||= begin
        ability = RegistrationCampaignAbility.new(current_user)
        # We need to merge TutorialAbility and TalkAbility because the view renders
        # registration items which delegate permission checks to their registerables
        # (Tutorials/Talks). Without this, can?(:destroy, item.registerable) fails.
        ability.merge(TutorialAbility.new(current_user))
        ability.merge(TalkAbility.new(current_user))
        ability
      end
    end

    def index
      authorize! :index, Registration::Campaign.new(campaignable: @lecture)
      @campaigns = @lecture.registration_campaigns.includes(:registration_items)
                           .order(created_at: :desc)

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
        respond_with_success(t("registration.campaign.created"), tab: "items")
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

      if @campaign.destroy
        respond_with_destroy_success(lecture)
      else
        respond_with_error(@campaign.errors.full_messages.join(", "))
      end
    end

    def open
      update_status(:open, t("registration.campaign.opened"))
    end

    def close
      attributes = { status: :closed }
      if @campaign.registration_deadline > Time.current
        attributes[:registration_deadline] = Time.current
      end

      if @campaign.update(attributes)
        respond_with_success(t("registration.campaign.closed"))
      else
        respond_with_error(@campaign.errors.full_messages.join(", "))
      end
    end

    def reopen
      if @campaign.processing? || @campaign.completed?
        respond_with_error(t("registration.campaign.cannot_reopen_allocated"))
        return
      end

      update_status(:open, t("registration.campaign.reopened"))
    end

    def check_unlimited_items
      has_unlimited = @campaign.registration_items.any? { |i| i.capacity.nil? }

      respond_to do |format|
        format.json { render json: { has_unlimited_items: has_unlimited } }
      end
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        respond_with_error(t("registration.campaign.lecture_not_found"),
                           redirect_path: root_path)
      end

      def set_campaign
        @campaign = Registration::Campaign.find_by(id: params[:id])
        return if @campaign

        respond_with_error(t("registration.campaign.not_found"),
                           redirect_path: root_path)
      end

      def set_locale
        I18n.locale = @campaign&.locale_with_inheritance ||
                      @lecture&.locale_with_inheritance ||
                      I18n.locale
      end

      def campaign_params
        params.expect(
          registration_campaign: [:description, :allocation_mode,
                                  :registration_deadline]
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
        render turbo_stream: turbo_stream.update("campaigns_container",
                                                 partial: partial,
                                                 locals: locals)
      end

      def render_turbo_update(partial, locals)
        lecture = locals[:lecture] || @lecture || @campaign&.campaignable
        streams = [
          turbo_stream.update("campaigns_container", partial: partial, locals: locals),
          stream_flash
        ]
        streams += refresh_roster_streams(lecture)
        render turbo_stream: streams.compact
      end

      def refresh_roster_streams(lecture)
        return [] unless lecture

        group_type = view_context.roster_group_types(lecture)
        frame_id = view_context.roster_maintenance_frame_id(group_type)

        [
          turbo_stream.replace(frame_id,
                               view_context.turbo_frame_tag(frame_id,
                                                            src: view_context.lecture_roster_path(
                                                              lecture, group_type: group_type
                                                            ),
                                                            loading: "lazy"))
        ]
      end

      def respond_with_success(message, tab: nil)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign, tab: tab), notice: message
          end
          format.turbo_stream do
            flash.now[:notice] = message
            render_turbo_update("registration/campaigns/card_body_show",
                                campaign: @campaign, tab: tab)
          end
        end
      end

      def respond_with_destroy_success(lecture)
        message = t("registration.campaign.destroyed")
        respond_to do |format|
          format.html do
            redirect_to lecture_registration_campaigns_path(lecture),
                        notice: message
          end
          format.turbo_stream do
            flash.now[:notice] = message
            render_turbo_update("registration/campaigns/card_body_index",
                                lecture: lecture)
          end
        end
      end

      def respond_with_form_error(message, action)
        respond_to do |format|
          format.html { render action, status: :unprocessable_content }
          format.turbo_stream do
            flash.now[:alert] = message
            render_turbo_update("registration/campaigns/card_body_form",
                                campaign: @campaign,
                                lecture: @campaign.campaignable)
          end
        end
      end

      def respond_with_error(message, redirect_path: nil)
        respond_to do |format|
          format.html do
            path = redirect_path || registration_campaign_path(@campaign)
            redirect_to path, alert: message
          end
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: stream_flash
          end
        end
      end
  end
end
