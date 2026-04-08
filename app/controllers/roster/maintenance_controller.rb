module Roster
  # Manages group allocations through a lecture-level overview and a polymorphic
  # item dashboard. Handles student membership visualization and maintenance actions.
  class MaintenanceController < ApplicationController
    class RosterLockedError < StandardError; end
    class UserNotFoundError < StandardError; end

    before_action :set_lecture, only: [:index, :participants]
    before_action :set_rosterable,
                  only: [:show, :add_member, :remove_member, :move_member,
                         :update_self_materialization, :bulk_update_self_materialization]
    before_action :build_maintenance_params
    before_action :authorize_lecture
    before_action :use_lecture_locale

    rescue_from "Rosters::UserAlreadyInBundleError" do |e|
      respond_with_error(t("roster.errors.user_already_in_bundle",
                           group: e.conflicting_group.title))
    end

    rescue_from "Rosters::MaintenanceService::CapacityExceededError" do
      respond_with_error(t("roster.errors.capacity_exceeded"))
    end

    rescue_from RosterLockedError do
      respond_with_error(t("roster.errors.item_locked"))
    end

    rescue_from UserNotFoundError do
      respond_with_error(t("roster.errors.user_not_found"))
    end

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: exception.message
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    # GET /lectures/:lecture_id/roster
    def index
      if params[:tab] == "participants"
        return redirect_to lecture_roster_participants_path(
          @lecture, params.permit(:filter, :search, :group_type)
        )
      end

      @group_type = @mparams.group_type
      setup_participants
    end

    # GET /lectures/:lecture_id/roster/participants
    def participants
      @group_type = @mparams.group_type
      setup_participants
    end

    def show
      if @mparams.panel?
        render_with_streams(stream_builder.streams(update_tiles: false))
      else
        redirect_to lecture_roster_path(@lecture)
      end
    end

    def add_member
      ensure_rosterable_unlocked!

      user = find_user
      Rosters::MaintenanceService.new.add_user!(user, @rosterable, force: true)

      flash.now[:notice] = t("roster.messages.user_added")
      flash.now[:alert] = t("roster.warnings.capacity_exceeded") if @rosterable.over_capacity?

      source = find_panel_source
      if source
        render_with_streams(
          stream_builder(rosterable: source, target: @rosterable)
            .streams(variant: :move_panel)
        )
      else
        render_with_streams(stream_builder.streams)
      end
    end

    def remove_member
      ensure_rosterable_unlocked!

      user = find_user
      Rosters::MaintenanceService.new.remove_user!(user, @rosterable)

      flash.now[:notice] = t("roster.messages.user_removed")

      render_with_streams(stream_builder.streams)
    end

    def move_member
      ensure_rosterable_unlocked!

      user = find_user
      target = Rosters::RosterableResolver.find_target(
        @mparams.target_id,
        type: @mparams.target_type,
        lecture: @lecture,
        default_type: @rosterable.class.name
      )

      if target.nil?
        respond_with_error(t("roster.errors.target_not_found"))
        return
      end

      if target.locked?
        respond_with_error(t("roster.errors.target_locked"))
        return
      end

      Rosters::MaintenanceService.new.move_user!(user, @rosterable, target, force: true)

      flash.now[:notice] = t("roster.messages.user_moved", target: target.title)
      flash.now[:alert] = t("roster.warnings.capacity_exceeded") if target.over_capacity?

      if @mparams.panel?
        render_with_streams(
          stream_builder(target: target).streams(variant: :move_panel)
        )
      else
        render_with_streams(stream_builder.streams)
      end
    end

    def update_self_materialization
      mode = @mparams.mode

      if @rosterable.update(self_materialization_mode: mode)
        render turbo_stream: turbo_stream.replace(
          @rosterable,
          html: GroupTileComponent.new(
            registerable: @rosterable
          ).render_in(view_context)
        )
      else
        respond_with_error(@rosterable.errors.full_messages.to_sentence)
      end
    end

    def bulk_update_self_materialization
      mode = @mparams.mode
      query = Rosters::NoCampaignRegisterablesQuery.new(@lecture)

      ActiveRecord::Base.transaction do
        query.scopes_by_type.each do |scope|
          scope.update_all(self_materialization_mode: mode) # rubocop:disable Rails/SkipsModelValidations
        end
      end

      render turbo_stream: refresh_campaigns_index_stream(@lecture)
    rescue StandardError => e
      respond_with_error(e.message)
    end

    private

      def setup_participants
        query = Rosters::ParticipantQuery.new(@lecture, params).call

        @participants_filter = query.filter_mode
        @total_participants_count = query.total_count
        @unassigned_participants_count = query.unassigned_count
        @search_string = @mparams.search

        @pagy, @participants = pagy(query.scope)
      end

      def authorize_lecture
        authorize! :edit, @lecture
      end

      def render_with_streams(streams)
        respond_to do |format|
          format.turbo_stream do
            streams << stream_flash if flash.present?
            render turbo_stream: streams
          end
          format.html do
            redirect_back_or_to fallback_path,
                                notice: flash.now[:notice],
                                alert: flash.now[:alert]
          end
        end
      end

      def stream_builder(target: nil, rosterable: nil)
        ensure_participants_state!

        Rosters::StreamBuilder.new(
          view_context: view_context,
          turbo_stream: turbo_stream,
          lecture: @lecture,
          rosterable: rosterable || @rosterable,
          mparams: @mparams,
          target: target,
          roster_tab: @mparams.roster_tab,
          participants_state: {
            participants: @participants,
            pagy: @pagy,
            filter_mode: @participants_filter,
            search_string: @search_string,
            total_count: @total_participants_count,
            unassigned_count: @unassigned_participants_count
          },
          refresh_campaigns_stream: lambda do |lecture|
            refresh_campaigns_index_stream(lecture)
          end
        )
      end

      def ensure_participants_state!
        return if @participants

        @group_type ||= @mparams.group_type
        setup_participants
      end

      def find_user
        user = if @mparams.user_id
          User.find_by(id: @mparams.user_id)
        else
          User.find_by(email: @mparams.email)
        end
        raise(UserNotFoundError) unless user

        user
      end

      def find_panel_source
        return unless @mparams.panel?
        return if @mparams.source_type.blank?
        return if @mparams.source_id.blank?

        source = Rosters::RosterableResolver.find_target(
          @mparams.source_id,
          type: @mparams.source_type,
          lecture: @lecture,
          default_type: @rosterable.class.name
        )

        source if source && source != @rosterable
      end

      def ensure_rosterable_unlocked!
        raise(RosterLockedError) if @rosterable.locked?
      end

      def fallback_path
        lecture_roster_path(@lecture, group_type: @rosterable&.roster_group_type || :all)
      end

      def set_lecture
        @lecture = Rosters::RosterableResolver.eager_load_lecture(params[:lecture_id])
        return if @lecture

        redirect_to root_path, alert: t("roster.errors.lecture_not_found")
      end

      def set_rosterable
        unless Rosters::Rosterable::TYPES.include?(params[:type])
          redirect_to root_path, alert: t("roster.errors.invalid_type")
          return
        end

        @rosterable = Rosters::RosterableResolver.resolve(params)
        unless @rosterable
          redirect_to root_path, alert: t("roster.errors.rosterable_not_found")
          return
        end

        lecture_id = if @rosterable.is_a?(Lecture)
          @rosterable.id
        elsif @rosterable.respond_to?(:lecture_id) && @rosterable.lecture_id
          @rosterable.lecture_id
        elsif @rosterable.is_a?(Cohort)
          @rosterable.context_id
        end

        @lecture = Rosters::RosterableResolver.eager_load_lecture(lecture_id)
        @rosterable = Rosters::RosterableResolver.reload(
          @rosterable,
          lecture: @lecture
        )

        return if @rosterable && @lecture

        redirect_to root_path, alert: t("roster.errors.rosterable_not_found")
      end

      def build_maintenance_params
        @mparams = Rosters::MaintenanceParams.new(params, lecture: @lecture)
      end

      def respond_with_error(message)
        respond_to do |format|
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: stream_flash
          end
          format.html { redirect_back_or_to fallback_path, alert: message }
        end
      end

      def use_lecture_locale
        locale = @lecture&.locale_with_inheritance || I18n.default_locale
        I18n.locale = locale
      end
  end
end
