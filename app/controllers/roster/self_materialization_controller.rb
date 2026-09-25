module Roster
  # For students to add/remove themselves from tutorial/talk/cohort rosters
  # Guarded by config_allow_self_add/config_allow_self_remove on the rosterable and locked? status
  class SelfMaterializationController < ApplicationController
    include Lectures::HomeStreams

    helper ::UserRegistrationsHelper
    before_action :set_rosterable, only: [:self_add, :self_remove, :self_switch]
    before_action :authorize_lecture
    before_action :require_personal_data, only: [:self_add, :self_switch]

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

    rescue_from "Rosters::MaintenanceService::GradingDataPresentError" do
      respond_with_error(t("roster.errors.switch_failed"))
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

    def self_switch
      from = @rosterable.conflicting_lecture_membership(current_user)
      moved = from && Rosters::SelfMaterializationService.new(@rosterable, current_user)
                                                         .self_switch!(from)
      return respond_with_error(t("roster.errors.switch_failed")) unless moved

      respond_with_success(t("roster.messages.user_switched", group: @rosterable.title))
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
            render turbo_stream: lecture_home_streams(@lecture, self_enrollment: true)
          end
        end
      end

      def set_rosterable
        @rosterable = Rosters::RosterableResolver.resolve(params)
        @lecture = rosterable_lecture

        return if @rosterable && @lecture

        redirect_to root_path, alert: t("roster.errors.rosterable_not_found")
      end

      def rosterable_lecture
        return @rosterable.lecture if @rosterable.respond_to?(:lecture)

        @rosterable.context if @rosterable.respond_to?(:context)
      end

      def roster_message_user
        current_user.info
      end
  end
end
