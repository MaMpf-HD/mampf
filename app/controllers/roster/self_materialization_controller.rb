module Roster
  class SelfMaterializationController < ApplicationController
    class RosterLockedError < StandardError; end
    class RosterFullError < StandardError; end
    class SelfAddNotAllowedError < StandardError; end
    class SelfRemoveNotAllowedError < StandardError; end
    class UserNotFoundError < StandardError; end

    ALLOWED_ROSTERABLE_TYPES = ["Tutorial", "Talk", "Cohort", "Lecture"].freeze

    before_action :set_rosterable, only: [:self_add, :self_remove]
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

    rescue_from RosterFullError do
      respond_with_error(t("roster.errors.capacity_exceeded"))
    end

    rescue_from SelfAddNotAllowedError do
      respond_with_error(t("roster.errors.self_add_not_allowed",
                           type: @rosterable.class.model_name.human))
    end

    rescue_from SelfRemoveNotAllowedError do
      respond_with_error(t("roster.errors.self_remove_not_allowed",
                           type: @rosterable.class.model_name.human))
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def self_add
      ensure_rosterable_unlocked!
      ensure_rosterable_not_full!
      ensure_rosterable_allow_self_add!

      user = current_user
      Rosters::MaintenanceService.new.add_user!(user, @rosterable, force: false)

      flash.now[:notice] = t("roster.messages.user_added")

      # need to re-render the roster partial to show the updated roster
      render_user_update(params[:turbo_frame],
                         params[:partial],
                         { params[:variable].to_sym => @rosterable })
    end

    def self_remove
      ensure_rosterable_unlocked!
      ensure_rosterable_allow_self_remove!

      user = current_user
      Rosters::MaintenanceService.new.remove_user!(user, @rosterable)

      flash.now[:notice] = t("roster.messages.user_removed")

      render_user_update(params[:turbo_frame],
                         params[:partial],
                         { params[:variable].to_sym => @rosterable })
    end

    private

      def ensure_rosterable_unlocked!
        raise(RosterLockedError) if @rosterable.locked?
      end

      def ensure_rosterable_not_full!
        raise(RosterLockedError) if @rosterable.full?
      end

      def ensure_rosterable_allow_self_add!
        raise(SelfAddNotAllowedError) unless @rosterable.config_allow_self_add?
      end

      def ensure_rosterable_allow_self_remove!
        raise(SelfRemoveNotAllowedError) unless @rosterable.config_allow_self_remove?
      end

      def respond_with_error(message)
        respond_to do |format|
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: stream_flash
          end
        end
      end

      def render_user_update(turbo_frame, partial, locals = {})
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              turbo_frame,
              partial: partial,
              locals: locals
            )
          end
        end
      end

      def set_rosterable
        unless ALLOWED_ROSTERABLE_TYPES.include?(params[:type])
          redirect_to root_path, alert: t("roster.errors.invalid_type")
          return
        end

        klass = params[:type].constantize
        param_key = "#{params[:type].underscore}_id"
        id = params[param_key] || params[:id]
        rosterable = klass.find_by(id: id)

        if rosterable&.lecture
          @lecture = Lecture.find_by(id: rosterable.lecture.id)

          case rosterable
          when Lecture
            @rosterable = @lecture
          when Tutorial
            @rosterable = @lecture.tutorials.find_by(id: rosterable.id) || rosterable
          when Talk
            @rosterable = @lecture.talks.find_by(id: rosterable.id) || rosterable
          when Cohort
            @rosterable = @lecture.cohorts.find_by(id: rosterable.id) || rosterable
          end
        end

        return if @rosterable && @lecture

        redirect_to root_path, alert: t("roster.errors.rosterable_not_found")
      end

      def use_lecture_locale
        locale = @lecture&.locale_with_inheritance || I18n.default_locale
        I18n.locale = locale
      end
  end
end
