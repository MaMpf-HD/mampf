module Roster
  # Manages group allocations through a lecture-level overview and a polymorphic
  # item dashboard. Handles student membership visualization and maintenance actions.
  class MaintenanceController < ApplicationController
    class RosterLockedError < StandardError; end
    class UserNotFoundError < StandardError; end

    before_action :set_lecture, only: [:index, :participants]
    before_action :set_rosterable,
                  only: [:show, :add_member, :remove_member, :move_member,
                         :update_self_materialization]
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

      setup_participants
    end

    # GET /lectures/:lecture_id/roster/participants
    def participants
      @group_type = if params[:group_type].is_a?(Array)
        params[:group_type].map(&:to_sym)
      else
        params[:group_type]&.to_sym || :all
      end

      setup_participants
    end

    def show
      if panel_source?
        render_panel_update(update_tiles: false)
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

      panel_source? ? render_panel_update : render_roster_update
    end

    def remove_member
      ensure_rosterable_unlocked!

      user = find_user
      Rosters::MaintenanceService.new.remove_user!(user, @rosterable)

      flash.now[:notice] = t("roster.messages.user_removed")
      panel_source? ? render_panel_update : render_roster_update
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

      if panel_source?
        render_move_panel_update(target)
      else
        render_roster_update
      end
    end

    def update_self_materialization
      mode = params[:mode]

      if @rosterable.update(self_materialization_mode: mode)
        render turbo_stream: turbo_stream.replace(
          @rosterable,
          partial: "registration/campaigns/group_tile",
          locals: { tutorial: @rosterable }
        )
      else
        respond_with_error(@rosterable.errors.full_messages.to_sentence)
      end
    end

    private

      def setup_participants
        query = Rosters::ParticipantQuery.new(@lecture, params).call

        @participants_filter = query.filter_mode
        @total_participants_count = query.total_count
        @unassigned_participants_count = query.unassigned_count

        @pagy, @participants = pagy(query.scope)
      end

      def authorize_lecture
        authorize! :edit, @lecture
      end

      def panel_source?
        params[:source] == "panel"
      end

      def render_panel_update(update_tiles: true)
        @rosterable.reload

        streams = []
        tile_replacements_for(@rosterable, streams) if update_tiles

        if @rosterable.is_a?(Tutorial) || @rosterable.is_a?(Cohort)
          streams << turbo_stream.replace(
            "tutorial-roster-side-panel",
            partial: "registration/campaigns/tutorial_roster_side_panel",
            locals: {
              registerable: @rosterable,
              students: @rosterable.members.order(:name)
            }
          )
        end

        streams << stream_flash if flash.present?
        render turbo_stream: streams.compact
      end

      def render_move_panel_update(target)
        @rosterable.reload
        target.reload

        streams = []

        tile_replacements_for(@rosterable, streams)
        tile_replacements_for(target, streams)

        streams << turbo_stream.replace(
          "tutorial-roster-side-panel",
          partial: "registration/campaigns/tutorial_roster_side_panel",
          locals: {
            registerable: @rosterable,
            students: @rosterable.members.order(:name)
          }
        )

        streams << stream_flash if flash.present?
        render turbo_stream: streams.compact
      end

      def tile_replacements_for(rosterable, streams)
        Registration::Item.where(registerable: rosterable).each do |item|
          streams << turbo_stream.replace(
            view_context.dom_id(item),
            partial: "registration/campaigns/group_tile",
            locals: { item: item }
          )
        end

        streams << turbo_stream.replace(
          view_context.dom_id(rosterable),
          partial: "registration/campaigns/group_tile",
          locals: { tutorial: rosterable }
        )
      end

      def render_roster_update(roster_tab: nil, rosterable: @rosterable)
        @lecture = eager_load_lecture(@lecture.id)
        rosterable = reload_rosterable_from_lecture(rosterable)
        setup_participants

        roster_tab = infer_roster_tab(roster_tab, rosterable)
        target_rosterable = determine_target_rosterable(roster_tab, rosterable)
        group_type = normalize_group_type
        frame_id = resolve_frame_id(group_type)
        component_counts = build_component_counts

        respond_to do |format|
          format.turbo_stream do
            streams = [
              turbo_stream.update(
                frame_id,
                RosterOverviewComponent.new(lecture: @lecture,
                                            group_type: group_type,
                                            roster_tab: roster_tab,
                                            rosterable: target_rosterable,
                                            participants: @participants,
                                            pagy: @pagy,
                                            filter_mode: @participants_filter,
                                            counts: component_counts)
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

      def reload_rosterable_from_lecture(rosterable)
        return rosterable if rosterable.nil? || rosterable.is_a?(Lecture)

        collection = case rosterable
                     when Tutorial then @lecture.tutorials
                     when Talk then @lecture.talks
                     when Cohort then @lecture.cohorts
        end
        collection&.find { |r| r.id == rosterable.id } || rosterable
      end

      def determine_target_rosterable(roster_tab, rosterable)
        return nil if roster_tab == :enrollment
        return nil if roster_tab == :participants
        return nil if rosterable.is_a?(Lecture)

        rosterable
      end

      def infer_roster_tab(roster_tab, rosterable)
        if roster_tab
          tab = roster_tab.to_sym
          return :enrollment if tab == :participants

          return tab
        end

        rosterable.is_a?(Lecture) ? :enrollment : :lanes
      end

      def normalize_group_type
        group_type = if params[:group_type].is_a?(Array)
          params[:group_type].map(&:to_sym)
        else
          fallback = if @rosterable.is_a?(Lecture)
            :all
          else
            @rosterable&.roster_group_type || :all
          end
          params[:group_type]&.to_sym || fallback
        end

        group_type.is_a?(Array) ? group_type : group_type&.to_sym
      end

      def resolve_frame_id(group_type)
        expected_frame_id = view_context.roster_maintenance_frame_id(group_type)
        allowed_frame_ids = allowed_roster_frame_ids

        allowed_frame_ids.include?(expected_frame_id) ? expected_frame_id : allowed_frame_ids.first
      end

      def build_component_counts
        {
          total: @total_participants_count,
          unassigned: @unassigned_participants_count
        }
      end

      def allowed_roster_frame_ids
        group_types = [
          :all,
          *RosterOverviewComponent::SUPPORTED_TYPES.keys,
          view_context.roster_group_types(@lecture)
        ].uniq

        frame_ids = group_types.map { |t| view_context.roster_maintenance_frame_id(t) }
        raise("No valid roster frame IDs generated") if frame_ids.empty?

        frame_ids
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

      def fallback_path
        lecture_roster_path(@lecture, group_type: @rosterable&.roster_group_type || :all)
      end

      def find_target_rosterable(id)
        target_type = params[:target_type]

        return nil if target_type.present? && Rosters::Rosterable::TYPES.exclude?(target_type)

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

      def set_lecture
        @lecture = eager_load_lecture(params[:lecture_id])
        return if @lecture

        redirect_to root_path, alert: t("roster.errors.lecture_not_found")
      end

      def set_rosterable
        unless Rosters::Rosterable::TYPES.include?(params[:type])
          redirect_to root_path, alert: t("roster.errors.invalid_type")
          return
        end

        klass = params[:type].constantize
        param_key = "#{params[:type].underscore}_id"
        id = params[param_key] || params[:id]
        rosterable = klass.find_by(id: id)

        if rosterable&.lecture
          @lecture = eager_load_lecture(rosterable.lecture.id)

          if @lecture
            if rosterable.is_a?(Lecture)
              @rosterable = @lecture
            else
              collection = case rosterable
                           when Tutorial then @lecture.tutorials
                           when Talk then @lecture.talks
                           when Cohort then @lecture.cohorts
              end
              @rosterable = collection&.find { |r| r.id == rosterable.id } || rosterable
            end
          else
            @rosterable = rosterable
          end
        else
          @rosterable = rosterable
        end

        return if @rosterable && @lecture

        redirect_to root_path, alert: t("roster.errors.rosterable_not_found")
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
          { registration_campaigns: [:user_registrations, :registration_items,
                                     :registration_policies] },
          tutorials: [:tutors, :tutorial_memberships,
                      { registration_items: { registration_campaign: :registration_policies } }],
          cohorts: [:cohort_memberships,
                    { registration_items: { registration_campaign: :registration_policies } }],
          talks: [:speakers, :speaker_talk_joins,
                  { registration_items: { registration_campaign: :registration_policies } }]
        ).find_by(id: id)
      end

      def use_lecture_locale
        locale = @lecture&.locale_with_inheritance || I18n.default_locale
        I18n.locale = locale
      end
  end
end
