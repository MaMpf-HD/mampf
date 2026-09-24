module Lectures
  class HomeController < ApplicationController
    helper ::UserRegistrationsHelper,
           ::LectureHomeHelper,
           ::Registration::ItemsHelper,
           ::Registration::CampaignsHelper

    before_action :set_lecture

    def current_ability
      @current_ability ||= RegistrationUserRegistrationAbility.new(current_user)
    end

    def show
      authorize! :index, @lecture

      load_student_registration if Registration::Participation.allowed?(current_user, @lecture)
      @notifications = current_user.active_notifications(@lecture)
      @new_topics_count = @lecture.unread_forum_topics_count(current_user) || 0
      @subscribed = @lecture.in?(current_user.lectures)
      # Roster members may subscribe without the passphrase, see
      # ProfileController#subscribe_lecture.
      @passphrase_required = @lecture.restricted? &&
                             !LectureMembership.exists?(user: current_user,
                                                        lecture: @lecture)
      @tutorials_given = @lecture.tutorials.includes(:tutors, :members)
                                 .select { |tutorial| current_user.in?(tutorial.tutors) }
      @managed_campaigns = managed_campaigns

      render template: "lectures/home/lecture_home",
             layout: turbo_frame_request? ? "turbo_frame" : "application"
    end

    def attachment
      authorize! :index, @lecture

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

      # Only open campaigns get their options and rules loaded; the others are
      # reported through the overview without them.
      def load_student_registration
        @overview = ::UserRegistrations::LectureOverview.new(@lecture, current_user)
        @open_campaign_details = if current_ability.can?(:create, @lecture)
          @overview.open_campaigns.map do |campaign|
            ::UserRegistrations::CampaignDetailsService.new(campaign, current_user).call
          end
        else
          []
        end
        @self_rosterables = Array(Rosters::SelfRosterOptionsQuery.new(@lecture, current_user).call)
      end

      def managed_campaigns
        return [] unless current_user.can_edit?(@lecture)

        Registration::Campaign.where(campaignable: @lecture)
                              .includes(:user_registrations)
                              .order(:registration_deadline)
      end

      def set_lecture
        lecture_id = params[:lecture_id]&.to_i || params[:id]&.to_i
        @lecture = Lecture.find_by(id: lecture_id)
        return if @lecture

        respond_with_flash(:alert, t("registration.lecture.not_found"),
                           fallback_location: root_path)
      end
  end
end
