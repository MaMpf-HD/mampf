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

      @can_edit = current_user.can_edit?(@lecture)
      @subscribed = @lecture.in?(current_user.lectures)
      # Roster members may subscribe without the passphrase, see
      # ProfileController#subscribe_lecture.
      @passphrase_required = @lecture.restricted? &&
                             !LectureMembership.exists?(user: current_user,
                                                        lecture: @lecture)
      @notifications = current_user.active_notifications(@lecture)
      @new_topics_count = @lecture.unread_forum_topics_count(current_user) || 0
      load_student_registration if Registration::Participation.allowed?(current_user, @lecture)
      load_tutor_work
      load_student_work if student_work?
      load_teacher_work if @can_edit

      render template: "lectures/home/lecture_home",
             layout: turbo_frame_request? ? "turbo_frame" : "application"
    end

    # Renders the options of one open campaign when its row is first opened, so
    # the page itself carries only the collapsed rows.
    def campaign
      authorize! :index, @lecture

      campaign = Registration::Campaign.find_by(id: params[:campaign_id], campaignable: @lecture)
      return head(:not_found) unless campaign&.open_for_registrations? && may_register?

      details = ::UserRegistrations::CampaignDetailsService.new(campaign, current_user).call
      component = CampaignCardComponent.new(details: details, campaign: campaign, part: :body)
      render turbo_stream: turbo_stream.replace(component.body_id,
                                                html: component.render_in(view_context))
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

      def may_register?
        Registration::Participation.allowed?(current_user, @lecture) &&
          current_ability.can?(:create, @lecture)
      end

      def load_student_registration
        @overview = ::UserRegistrations::LectureOverview.new(@lecture, current_user)
        @campaign_summaries = if current_ability.can?(:create, @lecture)
          @overview.open_campaigns.map do |campaign|
            ::UserRegistrations::CampaignDetailsService
              .new(campaign, current_user)
              .summary(own_registrations: @overview.registrations_for(campaign))
          end
        else
          []
        end
        @self_rosterables = Array(Rosters::SelfRosterOptionsQuery.new(@lecture, current_user).call)
        @next_exam = next_exam
      end

      def student_work?
        @subscribed && !@can_edit && @tutorials_given.empty? && @lecture.assignments.exists?
      end

      def load_student_work
        @work = Assessment::SubmissionsHub::Loader.new(lecture: @lecture, user: current_user)
                                                  .summary
        return unless @lecture.uses_exam_eligibility?

        @certification = StudentPerformance::Certification.find_by(lecture: @lecture,
                                                                   user: current_user)
      end

      def load_tutor_work
        @tutorials_given = current_user.given_tutorials.where(lecture: @lecture).to_a
        return if @tutorials_given.empty?

        @member_counts = TutorialMembership.where(tutorial_id: @tutorials_given.map(&:id))
                                           .group(:tutorial_id).count
        @tutor_backlog = MarkingBacklog.new(@lecture, tutorials: @tutorials_given)
      end

      def load_teacher_work
        @managed_campaigns = Registration::Campaign.where(campaignable: @lecture)
                                                   .includes(registration_items: :registerable)
                                                   .order(:registration_deadline).to_a
        @campaign_counts = CampaignCounts.new(@managed_campaigns).to_h
        @lecture_backlog = MarkingBacklog.new(@lecture)
      end

      def next_exam
        ExamRosterEntry.active.where(user: current_user)
                       .joins(:exam)
                       .where(exams: { lecture_id: @lecture.id, date: Time.current.. })
                       .order("exams.date").first&.exam
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
