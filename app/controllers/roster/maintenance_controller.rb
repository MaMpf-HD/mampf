module Roster
  # Manages group allocations through a lecture-level overview and a polymorphic
  # item dashboard. Handles student membership visualization and maintenance actions.
  class MaintenanceController < ApplicationController
    class RosterLockedError < StandardError; end
    class UserNotFoundError < StandardError; end

    ALLOWED_ROSTERABLE_TYPES = ["Tutorial", "Talk"].freeze

    before_action :set_lecture, only: [:index, :enroll]
    before_action :set_rosterable, only: [:show, :update, :add_member, :remove_member, :move_member]
    before_action :authorize_lecture

    rescue_from StandardError do |e|
      respond_with_error(e.message)
    end

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
      @group_type = params[:group_type]&.to_sym || :all
      @active_tab = params[:tab]&.to_sym || :groups
    end

    def enroll
      set_rosterable_from_composite_id
      ensure_rosterable_unlocked!

      user = find_user
      Rosters::MaintenanceService.new.add_user!(user, @rosterable, force: true)

      flash.now[:notice] = t("roster.messages.user_added_to", group: @rosterable.title)
      flash.now[:alert] = t("roster.warnings.capacity_exceeded") if over_capacity?(@rosterable)

      render_roster_update(tab: :enrollment)
    end

    # GET /:rosterable_type/:rosterable_id/roster
    def show
      @active_tab = params[:tab] || "roster"
    end

    # PATCH /:rosterable_type/:rosterable_id/roster
    def update
      if @rosterable.update(rosterable_params)
        flash.now[:notice] = t("roster.messages.updated")
        render_roster_update
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
      flash.now[:alert] = t("roster.warnings.capacity_exceeded") if over_capacity?(@rosterable)

      render_roster_update(tab: params[:tab])
    end

    def remove_member
      ensure_rosterable_unlocked!

      user = find_user
      Rosters::MaintenanceService.new.remove_user!(user, @rosterable)

      flash.now[:notice] = t("roster.messages.user_removed")
      render_roster_update
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
      flash.now[:alert] = t("roster.warnings.capacity_exceeded") if over_capacity?(target)

      render_roster_update
    end

    private

      def authorize_lecture
        authorize! :edit, @lecture
      end

      def render_roster_update(tab: nil)
        active_tab = tab&.to_sym || :groups
        # If we are in the enrollment tab (candidates panel), we want to refresh the overview
        # instead of showing the detail view of the group we just added to.
        rosterable = active_tab == :enrollment ? nil : @rosterable

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update(
                "roster_maintenance_#{group_type_for_rosterable}",
                RosterOverviewComponent.new(lecture: @lecture,
                                            group_type: group_type_for_rosterable,
                                            active_tab: active_tab,
                                            rosterable: rosterable)
              ),
              stream_flash
            ]
          end
          format.html do
            redirect_back_or_to fallback_path, notice: flash.now[:notice], alert: flash.now[:alert]
          end
        end
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
        @rosterable = klass.find_by(id: id)

        return if @rosterable

        respond_with_error(t("roster.errors.rosterable_not_found"))
        nil
      end

      def over_capacity?(rosterable)
        return false unless rosterable.respond_to?(:capacity)
        return false if rosterable.capacity.nil?

        rosterable.roster_entries.count > rosterable.capacity
      end

      def fallback_path
        lecture_roster_path(@lecture, group_type: group_type_for_rosterable)
      end

      def find_target_rosterable(id)
        @lecture.tutorials.find_by(id: id) || @lecture.talks.find_by(id: id)
      end

      def rosterable_params
        params.expect(rosterable: [:manual_roster_mode])
      end

      def group_type_for_rosterable
        case @rosterable
        when Tutorial then :tutorials
        when Talk then :talks
        else :all
        end
      end

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
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
  end
end
