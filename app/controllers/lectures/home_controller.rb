module Lectures
  class HomeController < ApplicationController
    helper ::UserRegistrationsHelper,
           ::Registration::ItemsHelper,
           ::Registration::CampaignsHelper

    before_action :set_lecture
    before_action :set_user_locale

    def current_ability
      @current_ability ||= RegistrationUserRegistrationAbility.new(current_user)
    end

    def show
      authorize! :index, @lecture

      @can_use_registration_workflow = current_ability.can?(:create, @lecture)

      @campaigns_details = Array(
        ::UserRegistrations::LectureCampaignsService
          .new(@lecture, current_user)
          .call
      )
      @rosterized_entries = Array(
        Rosters::StudentMaterializedResultResolver
          .new(current_user)
          .all_rosterized_for_lecture(@lecture)
      )
      @self_rosterables = Array(
        Rosters::SelfRosterOptionsQuery.new(@lecture, current_user).call
      )
      @show_workflow_content = @can_use_registration_workflow ||
                               @rosterized_entries.any? ||
                               @self_rosterables.any?
      @notifications = current_user.active_notifications(@lecture)
      @new_topics_count = @lecture.unread_forum_topics_count(current_user) || 0
      @subscribed = @lecture.in?(current_user.lectures)
      # Roster members may subscribe without the passphrase, see
      # ProfileController#subscribe_lecture.
      @passphrase_required = @lecture.restricted? &&
                             !LectureMembership.exists?(user: current_user,
                                                        lecture: @lecture)

      render template: "lectures/home/lecture_home",
             layout: turbo_frame_request? ? "turbo_frame" : "application"
    end

    # Streams the teacher's home-page PDF program. Gated exactly like the home
    # page itself, so anyone who may view the page may download the file.
    def attachment
      authorize! :index, @lecture

      # The lecture exists — only its PDF is gone (e.g. a stale link after the
      # teacher removed it), so do not claim the lecture was not found.
      if @lecture.home_attachment.blank?
        return respond_with_flash(
          :alert,
          t("registration.lecture.home.attachment_missing"),
          fallback_location: lecture_home_path(@lecture)
        )
      end

      send_data(@lecture.home_attachment.read,
                filename: @lecture.home_attachment_filename || "program.pdf",
                type: "application/pdf",
                disposition: "inline")
    end

    private

      def set_lecture
        lecture_id = params[:lecture_id]&.to_i || params[:id]&.to_i
        @lecture = Lecture.find_by(id: lecture_id)
        return if @lecture

        respond_with_flash(:alert, t("registration.lecture.not_found"),
                           fallback_location: root_path)
      end
  end
end
