module Roster
  # For students to add/remove themselves from tutorial/talk/cohort rosters
  # Guarded by config_allow_self_add/config_allow_self_remove on the rosterable and locked? status
  class SelfMaterializationController < ApplicationController
    before_action :set_rosterable, only: [:self_add, :self_remove]
    before_action :use_lecture_locale
    before_action :authorize_lecture

    rescue_from "Rosters::UserAlreadyInBundleError" do |e|
      respond_with_error(t("roster.errors.user_already_in_bundle",
                           group: e.conflicting_group.title))
    end

    rescue_from "Rosters::MaintenanceService::CapacityExceededError" do
      respond_with_error(t("roster.errors.capacity_exceeded"))
    end

    rescue_from "Rosters::SelfMaterializationService::LectureHasOtherRosterEntryError" do
      respond_with_error(t("roster.errors.lecture_has_other_roster_entry"))
    end

    rescue_from "Rosters::SelfMaterializationService::RosterLockedError" do
      respond_with_error(t("roster.errors.item_locked"))
    end

    rescue_from "Rosters::SelfMaterializationService::RosterFullError" do
      respond_with_error(t("roster.errors.capacity_exceeded"))
    end

    rescue_from "Rosters::SelfMaterializationService::SelfAddNotAllowedError" do
      respond_with_error(t("roster.errors.self_add_not_allowed",
                           type: @rosterable.class.model_name.human))
    end

    rescue_from "Rosters::SelfMaterializationService::SelfRemoveNotAllowedError" do
      respond_with_error(t("roster.errors.self_remove_not_allowed",
                           type: @rosterable.class.model_name.human))
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def self_add
      service = Rosters::SelfMaterializationService.new(@rosterable, current_user)
      service.self_add!
      respond_with_success(t("roster.messages.user_added"))
    end

    def self_remove
      service = Rosters::SelfMaterializationService.new(@rosterable, current_user)
      service.self_remove!
      respond_with_success(t("roster.messages.user_removed"))
    end

    private

      def authorize_lecture
        authorize! :self_materialize, @lecture
      end

      def respond_with_error(message)
        respond_to do |format|
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: stream_flash
          end
        end
      end

      def respond_with_success(message)
        flash.now[:notice] = message
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "self_roster_options_zone",
              partial: "roster/self_roster/options_zone",
              locals: { self_rosterables: Rosters::SelfRosterOptionsQuery.new(@lecture, current_user).call }
            )
          end
        end
      end

      def set_rosterable
        unless Rosters::Rosterable::TYPES.include?(params[:type])
          redirect_to root_path, alert: t("roster.errors.invalid_type")
          return
        end

        klass = params[:type].constantize
        param_key = "#{params[:type].underscore}_id"
        id = params[param_key] || params[:id]
        @rosterable = klass.find_by(id: id)
        @lecture = @rosterable.lecture if @rosterable.respond_to?(:lecture)

        return if @rosterable && @lecture

        redirect_to root_path, alert: t("roster.errors.rosterable_not_found")
      end

      def use_lecture_locale
        locale = @lecture&.locale_with_inheritance || I18n.default_locale
        I18n.locale = locale
      end
  end
end
