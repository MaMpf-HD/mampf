module Roster
  # Manages group allocations through a lecture-level overview and a polymorphic
  # item dashboard. Handles student membership visualization and maintenance actions.
  class MaintenanceController < ApplicationController
    class RosterLockedError < StandardError; end
    class UserNotFoundError < StandardError; end

    ALLOWED_ROSTERABLE_TYPES = ["Tutorial", "Talk", "Cohort", "Lecture"].freeze

    before_action :set_lecture, only: [:index, :enroll]
    before_action :set_rosterable, only: [:show, :update, :add_member, :remove_member, :move_member]
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
      @group_type = if params[:group_type].is_a?(Array)
        params[:group_type].map(&:to_sym)
      else
        params[:group_type]&.to_sym || :all
      end
      @active_tab = params[:tab]&.to_sym || :groups

      setup_participants
    end

    def enroll
      set_rosterable_from_composite_id
      return unless @rosterable

      ensure_rosterable_unlocked!

      user = find_user
      Rosters::MaintenanceService.new.add_user!(user, @rosterable, force: true)

      flash.now[:notice] = t("roster.messages.user_added_to", group: @rosterable.title)
      flash.now[:alert] = t("roster.warnings.capacity_exceeded") if @rosterable.over_capacity?

      render_roster_update(tab: :enrollment)
    end

    def show
      @active_tab = params[:tab] || "roster"
      setup_participants
    end

    def update
      if @rosterable.update(rosterable_params)
        flash.now[:notice] = t("roster.messages.updated")
        render_roster_update(rosterable: nil)
      else
        redirect_to lecture_roster_path(@lecture),
                    alert: @rosterable.errors.full_messages.join(", ")
      end
    end

    def add_member
      ensure_rosterable_unlocked!

      user = find_user
      Rosters::MaintenanceService.new.add_user!(user, @rosterable, force: true)

      flash.now[:notice] = t("roster.messages.user_added")
      flash.now[:alert] = t("roster.warnings.capacity_exceeded") if @rosterable.over_capacity?

      render_roster_update(tab: params[:active_tab])
    end

    def remove_member
      ensure_rosterable_unlocked!

      user = find_user
      Rosters::MaintenanceService.new.remove_user!(user, @rosterable)

      flash.now[:notice] = t("roster.messages.user_removed")
      render_roster_update(tab: params[:active_tab])
    end

    def move_member
      ensure_rosterable_unlocked!

      user = find_user
      target = find_target_rosterable(params[:target_id])

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

      render_roster_update(tab: params[:active_tab])
    end

    private

      def setup_participants
        @participants_filter = params[:filter] || "all"
        base_scope = @lecture.lecture_memberships
                             .joins(:user)
                             .includes(:user)
                             .order(Arel.sql("COALESCE(NULLIF(users.name_in_tutorials, ''), users.name) ASC"))

        @total_participants_count = base_scope.count

        # Calculate unassigned scope
        # Users in tutorial memberships for this lecture
        # Note: We must NOT select 'id' to allow UNION to work with different primary
        # keys (UUID vs Integer)
        tutorial_user_ids = TutorialMembership.joins(:tutorial)
                                              .where(tutorials: { lecture_id: @lecture.id })
                                              .select(:user_id)

        # User in talk memberships for this lecture (via talks)
        talk_user_ids = SpeakerTalkJoin.joins(:talk)
                                       .where(talks: { lecture_id: @lecture.id })
                                       .select(:speaker_id)

        # Rails 7+ allows .union but can be finicky with different table structures / primary keys
        # We manually construct the SQL to be safe regardless of the primary key differences
        assigned_ids_sql = "(#{tutorial_user_ids.to_sql}) UNION (#{talk_user_ids.to_sql})"

        unassigned_scope = base_scope.where.not(user_id: Arel.sql(assigned_ids_sql))
        @unassigned_participants_count = unassigned_scope.count

        scope = case @participants_filter
                when "unassigned"
                  unassigned_scope
                else
                  base_scope
        end

        @pagy, @participants = pagy(scope)
      end

      def authorize_lecture
        authorize! :edit, @lecture
      end

      def render_roster_update(tab: nil, rosterable: @rosterable)
        # Ensure lecture is eager loaded and fresh (to include new memberships)
        @lecture = eager_load_lecture(@lecture.id)

        # Ensure participants are set up for the view
        setup_participants

        active_tab = tab&.to_sym || params[:active_tab]&.to_sym || :groups

        # Only set target_rosterable if we are in the groups tab, otherwise we risk
        # changing the hidden groups tab to a detail view unexpectedly.
        target_rosterable = active_tab == :groups ? rosterable : nil

        # If the rosterable is the lecture itself, we want to show the overview/list
        # in the groups tab, not a "detail view" of the lecture.
        target_rosterable = nil if target_rosterable.is_a?(Lecture)

        group_type = if params[:group_type].is_a?(Array)
          params[:group_type].map(&:to_sym)
        else
          params[:group_type]&.to_sym || @rosterable&.roster_group_type || :all
        end

        # Ensure group_type is formatted correctly (strings/symbols/arrays) for the helper
        group_type = group_type&.to_sym unless group_type.is_a?(Array)

        frame_id = params[:frame_id].presence
        frame_id = nil unless allowed_roster_frame_ids.include?(frame_id)
        frame_id ||= view_context.roster_maintenance_frame_id(group_type)

        respond_to do |format|
          format.turbo_stream do
            streams = [
              turbo_stream.update(
                frame_id,
                RosterOverviewComponent.new(lecture: @lecture,
                                            group_type: group_type,
                                            active_tab: active_tab,
                                            rosterable: target_rosterable,
                                            participants: @participants,
                                            pagy: @pagy,
                                            filter_mode: @participants_filter,
                                            counts: { total: @total_participants_count,
                                                      unassigned: @unassigned_participants_count })
              ),
              refresh_campaigns_index_stream(@lecture)
            ]
            streams << stream_flash if flash.present?
            render turbo_stream: streams
          end
          format.html do
            redirect_back_or_to fallback_path, notice: flash.now[:notice], alert: flash.now[:alert]
          end
        end
      end

      def allowed_roster_frame_ids
        group_types = [
          :all,
          *RosterOverviewComponent::SUPPORTED_TYPES.keys,
          view_context.roster_group_types(@lecture)
        ].uniq

        group_types.map { |t| view_context.roster_maintenance_frame_id(t) }
      end

      def find_user
        user = if params[:user_id]
          User.find_by(id: params[:user_id])
        else
          User.find_by(email: params[:email])
        end
        raise(UserNotFoundError) unless user

        user
      end

      def ensure_rosterable_unlocked!
        raise(RosterLockedError) if @rosterable.locked?
      end

      def set_rosterable_from_composite_id
        type, id = params[:rosterable_id].split("-")

        unless ALLOWED_ROSTERABLE_TYPES.include?(type)
          respond_with_error(t("roster.errors.invalid_type"))
          return
        end

        klass = type.constantize
        @rosterable = if klass == Cohort
          klass.find_by(id: id, context: @lecture)
        else
          klass.find_by(id: id, lecture: @lecture)
        end

        return if @rosterable

        respond_with_error(t("roster.errors.rosterable_not_found"))
        nil
      end

      def fallback_path
        lecture_roster_path(@lecture, group_type: @rosterable&.roster_group_type || :all)
      end

      def find_target_rosterable(id)
        target_type = params[:target_type]

        return nil if target_type.present? && ALLOWED_ROSTERABLE_TYPES.exclude?(target_type)

        target_type ||= @rosterable.class.name
        klass = target_type.constantize

        # Scope the search to the same type as the current group to avoid ID collisions
        # between Tutorials and Talks.
        if klass == Cohort
          klass.find_by(id: id, context: @lecture)
        else
          klass.find_by(id: id, lecture: @lecture)
        end
      end

      def rosterable_params
        params.expect(rosterable: [:manual_roster_mode])
      end

      def set_lecture
        @lecture = eager_load_lecture(params[:lecture_id])
        return if @lecture

        redirect_to root_path, alert: t("roster.errors.lecture_not_found")
      end

      def set_rosterable
        unless ALLOWED_ROSTERABLE_TYPES.include?(params[:type])
          redirect_to root_path, alert: t("roster.errors.invalid_type")
          return
        end

        klass = params[:type].constantize
        param_key = "#{params[:type].underscore}_id"
        id = params[param_key] || params[:id]
        @rosterable = klass.find_by(id: id)
        if @rosterable
          @lecture = @rosterable.lecture
        else
          redirect_to root_path, alert: t("roster.errors.rosterable_not_found")
        end
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

      def eager_load_lecture(id)
        Lecture.includes(
          { registration_campaigns: [:user_registrations, :registration_items] },
          tutorials: [:tutors, :tutorial_memberships,
                      { registration_items: :registration_campaign }],
          cohorts: [:cohort_memberships, { registration_items: :registration_campaign }],
          talks: [:speakers, :speaker_talk_joins, { registration_items: :registration_campaign }]
        ).find_by(id: id)
      end

      def use_lecture_locale
        locale = @lecture&.locale_with_inheritance || I18n.default_locale
        I18n.locale = locale
      end
  end
end
