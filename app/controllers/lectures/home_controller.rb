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

      @campaigns_details = ::UserRegistrations::LectureCampaignsService
                           .new(@lecture, current_user)
                           .call
      @rosterized_entries = Rosters::StudentMaterializedResultResolver
                            .new(current_user)
                            .all_rosterized_for_lecture(@lecture)
      @self_rosterables = Rosters::SelfRosterOptionsQuery.new(@lecture, current_user).call

      render template: "lectures/home/lecture_home",
             layout: turbo_frame_request? ? "turbo_frame" : "application"
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
