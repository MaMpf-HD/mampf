module Roster
  # For students to add/remove themselves from tutorial/talk/cohort rosters
  # Guarded by config_allow_self_add/config_allow_self_remove on the rosterable and locked? status
  class SelfMaterializationController < ApplicationController
    helper ::UserRegistrationsHelper, ::EligibilityHelper
    before_action :set_rosterable, only: [:self_add, :self_remove]
    before_action :use_user_locale
    before_action :authorize_lecture

    rescue_from "Rosters::UserAlreadyInBundleError" do |e|
      respond_with_error(t("roster.errors.user_already_in_bundle",
                           user: roster_message_user,
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
      respond_with_success(t("roster.messages.user_added",
                             user: roster_message_user,
                             group: @rosterable.title))
    end

    def self_remove
      service = Rosters::SelfMaterializationService.new(@rosterable, current_user)
      service.self_remove!
      respond_with_success(t("roster.messages.user_removed",
                             user: roster_message_user))
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
            render turbo_stream: [
              stream_flash,
              turbo_stream.update(
                "student_registration_rosterized_entries",
                html: RosterizedEntriesComponent.new(
                  rosterized_entries: Rosters::StudentMaterializedResultResolver
                                       .new(current_user)
                                       .all_rosterized_for_lecture(@lecture),
                  lecture: @lecture,
                  user: current_user
                ).render_in(view_context)
              ),
              turbo_stream.update(
                "self_materialization_zone",
                partial: "user_registrations/self_materialization_zone",
                locals: { self_rosterables: Rosters::SelfRosterOptionsQuery.new(@lecture, current_user).call }
              )
            ]
          end
        end
      end

      def set_rosterable
        klass = Rosters::Rosterable.class_for(params[:type])
        unless klass
          redirect_to root_path, alert: t("roster.errors.invalid_type")
          return
        end

        param_key = "#{params[:type].underscore}_id"
        id = params[param_key] || params[:id]
        @rosterable = klass.find_by(id: id)
        @lecture = @rosterable.lecture if @rosterable.respond_to?(:lecture)

        return if @rosterable && @lecture

        redirect_to root_path, alert: t("roster.errors.rosterable_not_found")
      end

      def use_user_locale
        locale = current_user&.locale.presence || I18n.default_locale
        I18n.locale = locale
      end

      def roster_message_user
        current_user.info
      end
  end
end
