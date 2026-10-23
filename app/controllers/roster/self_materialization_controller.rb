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
      key = action_name == "self_remove" ? "self_remove_graded" : "switch_failed"
      respond_with_error(t("roster.errors.#{key}", group: @rosterable.title))
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
      confirm_participation if params[:keep_course].present?
      respond_with_success(self_removed_message)
    end

    private

      # Leaving the last group but not the lecture answers the question the
      # participation check would ask.
      def confirm_participation
        @lecture.lecture_memberships.find_by(user: current_user)
                &.update!(participation_confirmed_at: Time.current)
      end

      # The lecture stays when a group goes, which students do not expect.
      def self_removed_message
        if @lecture.lecture_memberships.exists?(user: current_user)
          t("roster.messages.self_removed_still_enrolled",
            group: @rosterable.title, lecture: @lecture.title_term_info_no_type)
        else
          t("roster.messages.self_removed", group: @rosterable.title)
        end
      end

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
