module Registration
  class ItemsController < ApplicationController
    helper RosterHelper
    before_action :set_campaign
    before_action :set_locale
    before_action :set_item, only: [:destroy, :update, :roster]
    authorize_resource class: "Registration::Item", except: [:create]

    def current_ability
      @current_ability ||= begin
        ability = RegistrationItemAbility.new(current_user)
        # We need to merge TutorialAbility and TalkAbility because the view renders
        # registration items which delegate permission checks to their registerables
        # (Tutorials/Talks). Without this, can?(:destroy, item.registerable) fails.
        ability.merge(TutorialAbility.new(current_user))
        ability.merge(TalkAbility.new(current_user))
        ability.merge(CohortAbility.new(current_user))
        ability
      end
    end

    def create
      create_existing_item
    end

    def update
      if @item.update(capacity_params)
        respond_to do |format|
          format.html do
            redirect_to after_action_path,
                        notice: t("registration.item.updated")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.item.updated")
            streams = if ["allocation", "allocation_embedded"].include?(params[:source])
              embedded = params[:source] == "allocation_embedded"
              dashboard = Registration::AllocationDashboard.new(@campaign)
              [
                turbo_stream.replace("allocation-dashboard",
                                     partial: "registration/allocations/dashboard",
                                     locals: {
                                       campaign: @campaign,
                                       dashboard: dashboard,
                                       embedded: embedded
                                     }),
                turbo_stream.replace(@item,
                                     html: GroupTileComponent.new(
                                       registerable: @item.registerable,
                                       item: @item
                                     ).render_in(view_context)),
                stream_flash
              ]
            else
              [
                turbo_stream.replace(@item,
                                     html: GroupTileComponent.new(
                                       registerable: @item.registerable,
                                       item: @item
                                     ).render_in(view_context)),
                stream_flash
              ]
            end
            render turbo_stream: streams
          end
        end
      else
        messages = @item.errors.map(&:message)
        messages += @item.registerable.errors.map(&:message) if @item.registerable&.errors&.any?
        respond_with_error(messages.uniq.to_sentence)
      end
    end

    def destroy
      unless @campaign.draft?
        respond_with_error(t("activerecord.errors.models.registration/item.attributes.base.frozen"))
        return
      end

      @item.destroy
      respond_with_success(t("registration.item.destroyed"))
    end

    def roster
      unless params[:source] == "panel"
        redirect_to after_action_path
        return
      end

      students = panel_students_for(@item)
      allocated = @campaign.last_allocation_calculated_at.present?
      preference_ranks = allocated ? preference_ranks_for(@item) : {}

      render turbo_stream: turbo_stream.replace(
        "tutorial-roster-side-panel",
        html: RosterSidePanelComponent.new(
          registerable: @item.registerable,
          students: students,
          read_only: true,
          item: @item,
          allocated: allocated,
          preference_ranks: preference_ranks
        ).render_in(view_context)
      )
    end

    private

      def create_existing_item
        @item = @campaign.registration_items.build(item_params)
        authorize! :create, @item

        if @item.save
          respond_with_success(t("registration.item.created"))
        else
          respond_with_error(@item.errors.map(&:message).uniq.to_sentence)
        end
      end

      def respond_with_success(message)
        @campaign.reload
        respond_to do |format|
          format.html do
            redirect_to after_action_path, notice: message
          end
          format.turbo_stream do
            flash.now[:notice] = message
            streams = [
              turbo_stream.update("campaigns_container",
                                  partial: "registration/campaigns/card_body_index",
                                  locals: {
                                    lecture: @campaign.campaignable,
                                    expanded_campaign_id: @campaign.id
                                  }),
              stream_flash
            ]
            render turbo_stream: streams
          end
        end
      end

      def respond_with_error(message, redirect_path: nil)
        respond_to do |format|
          format.html do
            path = redirect_path || after_action_path
            redirect_to path, alert: message
          end
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: stream_flash
          end
        end
      end

      def set_campaign
        @campaign = Registration::Campaign.find_by(id: params[:registration_campaign_id])
        return if @campaign

        respond_with_error(t("registration.campaign.not_found"), redirect_path: root_path)
      end

      def set_locale
        I18n.locale = @campaign&.locale_with_inheritance || I18n.locale
      end

      def set_item
        @item = @campaign.registration_items.find_by(id: params[:id])
        return if @item

        respond_with_error(t("registration.item.not_found"))
      end

      def item_params
        params.expect(registration_item: [:registerable_id, :registerable_type])
      end

      def capacity_params
        params.expect(registration_item: [:capacity])
      end

      def after_action_path
        if @campaign.campaignable.is_a?(Lecture)
          lecture_roster_path(@campaign.campaignable,
                              group_type: view_context.roster_group_types(@campaign.campaignable),
                              tab: "enrollment")
        else
          registration_campaign_path(@campaign)
        end
      end

      def panel_students_for(item)
        registrations = if @campaign.last_allocation_calculated_at.present?
          item.user_registrations.confirmed
        elsif @campaign.first_come_first_served?
          item.user_registrations
        else
          item.user_registrations.where(preference_rank: 1)
        end

        registrations.includes(:user)
                     .filter_map(&:user)
                     .uniq(&:id)
                     .sort_by { |user| [user.name.to_s.downcase, user.email.to_s.downcase] }
      end

      def preference_ranks_for(item)
        item.registration_campaign
            .user_registrations
            .where(
              user_id: item.user_registrations.confirmed.select(:user_id),
              registration_item_id: item.id
            )
            .pluck(:user_id, :preference_rank)
            .to_h
      end
  end
end
