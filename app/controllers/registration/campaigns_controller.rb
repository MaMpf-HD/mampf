module Registration
  class CampaignsController < ApplicationController
    include Registration::RosterStreamRefreshable

    before_action :set_lecture, only: [:index, :new, :create]
    before_action :set_campaign, except: [:index, :new, :create]
    before_action :set_locale
    authorize_resource class: "Registration::Campaign", except: [:index, :new, :create]

    def current_ability
      @current_ability ||= RegistrationCampaignAbility.new(current_user)
    end

    def index
      authorize! :index, Registration::Campaign.new(campaignable: @lecture)
      @campaigns = @lecture.registration_campaigns.non_exam
                           .includes(:registration_items)
                           .order(created_at: :desc)

      respond_to do |format|
        format.html
        format.turbo_stream do
          render_campaigns_index_turbo(lecture: @lecture)
        end
      end
    end

    def show
      respond_to do |format|
        format.html
        format.turbo_stream do
          if exam_campaign_context?
            render_exam_update
          else
            render_campaigns_index_turbo(lecture: @campaign.campaignable,
                                         expanded_campaign_id: @campaign.id)
          end
        end
      end
    end

    def unassigned
      unless params[:source] == "panel"
        redirect_to edit_lecture_path(@campaign.campaignable, tab: "groups")
        return
      end

      render_campaign_panel(
        students: @campaign.unassigned_users(preload_registrations: true),
        panel_kind: :unassigned
      )
    end

    def rejected
      unless params[:source] == "panel"
        redirect_to edit_lecture_path(@campaign.campaignable, tab: "groups")
        return
      end

      render_campaign_panel(
        students: @campaign.rejected_users(preload_registrations: true),
        panel_kind: :rejected
      )
    end

    def new
      @campaign = @lecture.registration_campaigns.build
      @campaign.allocation_mode = :first_come_first_served
      authorize! :new, @campaign

      respond_to do |format|
        format.html
        format.turbo_stream do
          render_campaigns_index_turbo(lecture: @lecture,
                                       new_campaign: @campaign)
        end
      end
    end

    def edit
      render partial: "registration/campaigns/form",
             locals: { campaign: @campaign,
                       lecture: @campaign.campaignable }
    end

    def create
      @campaign = @lecture.registration_campaigns.build(campaign_params)
      authorize! :create, @campaign

      if @campaign.save
        respond_with_flash(:notice, t("registration.campaign.created"),
                           redirect_path: registration_campaign_path(@campaign)) do
          evaluate_turbo_update_streams(lecture: @campaign.campaignable,
                                        expanded_campaign_id: @campaign.id)
        end
      else
        respond_with_form_error(t("registration.campaign.create_failed"), :new)
      end
    end

    def update
      if @campaign.update(campaign_params)
        render partial: "registration/campaigns/card_header",
               locals: { campaign: @campaign }
      else
        render partial: "registration/campaigns/form",
               locals: { campaign: @campaign,
                         lecture: @campaign.campaignable },
               status: :unprocessable_content
      end
    end

    def destroy
      unless @campaign.can_be_deleted?
        respond_with_flash(:alert, t("registration.campaign.cannot_delete"),
                           redirect_path: registration_campaign_path(@campaign))
        return
      end

      lecture = @campaign.campaignable

      if @campaign.destroy
        respond_with_flash(:notice, t("registration.campaign.destroyed"),
                           redirect_path: lecture_registration_campaigns_path(lecture)) do
          evaluate_turbo_update_streams(lecture: lecture)
        end
      else
        respond_with_flash(:alert, @campaign.errors.full_messages.join(", "),
                           redirect_path: registration_campaign_path(@campaign))
      end
    end

    def open
      update_status(:open, t("registration.campaign.opened"))
    end

    def close
      attributes = { status: :closed }
      if @campaign.registration_deadline > Time.current
        attributes[:registration_deadline] = Time.current
      end

      if @campaign.update(attributes)
        if exam_campaign_context?
          render_exam_update
        else
          respond_with_flash(:notice, t("registration.campaign.closed"),
                             redirect_path: registration_campaign_path(@campaign)) do
            evaluate_turbo_update_streams(lecture: @campaign.campaignable,
                                          expanded_campaign_id: @campaign.id)
          end
        end
      else
        respond_with_flash(:alert, @campaign.errors.full_messages.join(", "),
                           redirect_path: registration_campaign_path(@campaign))
      end
    end

    def reopen
      if @campaign.completed?
        respond_with_flash(:alert, t("registration.campaign.cannot_reopen_completed"),
                           redirect_path: registration_campaign_path(@campaign))
        return
      end

      was_processing = @campaign.processing?

      attributes = { status: :open }
      if params[:registration_deadline].present?
        attributes[:registration_deadline] = params[:registration_deadline]
      end

      @campaign.transaction do
        @campaign.update!(attributes)
        @campaign.reset_allocation_results! if was_processing
      end

      if exam_campaign_context?
        render_exam_update
      else
        respond_with_flash(:notice, t("registration.campaign.reopened"),
                           redirect_path: registration_campaign_path(@campaign)) do
          evaluate_turbo_update_streams(lecture: @campaign.campaignable,
                                        expanded_campaign_id: @campaign.id)
        end
      end
    rescue ActiveRecord::RecordInvalid
      if exam_campaign_context?
        render_exam_update(exam: exam_with_campaign_errors,
                           status: :unprocessable_content)
      else
        respond_with_flash(:alert, @campaign.errors.full_messages.join(", "),
                           redirect_path: registration_campaign_path(@campaign))
      end
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        respond_with_flash(:alert, t("registration.campaign.lecture_not_found"),
                           redirect_path: root_path)
      end

      def set_campaign
        @campaign = Registration::Campaign.find_by(id: params[:id])
        return if @campaign

        respond_with_flash(:alert, t("registration.campaign.not_found"),
                           redirect_path: root_path)
      end

      def set_locale
        I18n.locale = @campaign&.locale_with_inheritance ||
                      @lecture&.locale_with_inheritance ||
                      I18n.locale
      end

      def campaign_params
        params.expect(
          registration_campaign: [:description, :allocation_mode,
                                  :registration_deadline]
        )
      end

      def render_campaign_panel(students:, panel_kind: nil)
        render turbo_stream: turbo_stream.replace(
          "tutorial-roster-side-panel",
          html: RosterSidePanelComponent.new(
            campaign: @campaign,
            students: students,
            panel_kind: panel_kind
          ).render_in(view_context)
        )
      end

      def update_status(status, success_message)
        if @campaign.update(status: status)
          if exam_campaign_context?
            render_exam_update
          else
            respond_with_flash(:notice, success_message,
                               redirect_path: registration_campaign_path(@campaign)) do
              evaluate_turbo_update_streams(lecture: @campaign.campaignable,
                                            expanded_campaign_id: @campaign.id)
            end
          end
        else
          respond_with_flash(:alert, @campaign.errors.full_messages.join(", "),
                             redirect_path: registration_campaign_path(@campaign))
        end
      end

      def render_campaigns_index_turbo(lecture:, expanded_campaign_id: nil,
                                       new_campaign: nil)
        render turbo_stream: turbo_stream.update(
          "campaigns_container",
          partial: "registration/campaigns/card_body_index",
          locals: {
            lecture: lecture,
            expanded_campaign_id: expanded_campaign_id,
            new_campaign: new_campaign
          }
        )
      end

      def evaluate_turbo_update_streams(lecture:, expanded_campaign_id: nil,
                                        new_campaign: nil)
        streams = [
          turbo_stream.update(
            "campaigns_container",
            partial: "registration/campaigns/card_body_index",
            locals: {
              lecture: lecture,
              expanded_campaign_id: expanded_campaign_id,
              new_campaign: new_campaign
            }
          )
        ]
        streams += refresh_roster_streams(lecture)
        streams.compact
      end

      def respond_with_form_error(_message, action)
        respond_to do |format|
          format.html { render action, status: :unprocessable_content }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "new_campaign_form",
              partial: "registration/campaigns/form",
              locals: { campaign: @campaign,
                        lecture: @campaign.campaignable }
            ), status: :unprocessable_content
          end
        end
      end

      def target_frame_id
        params[:frame_id].presence || "campaigns_container"
      end

      def exam_campaign_context?
        target_frame_id != "campaigns_container" &&
          @campaign.exam_campaign?
      end

      def render_exam_update(exam: @campaign.exam, status: :ok)
        render turbo_stream: [
          turbo_stream.replace(
            target_frame_id,
            partial: "exams/registration",
            locals: { exam: exam, lecture: exam.lecture }
          ),
          turbo_stream.replace(
            "exam-settings",
            partial: "exams/settings",
            locals: { exam: exam, lecture: exam.lecture }
          ),
          turbo_stream.replace(
            "exam_#{exam.id}_registration_tab_label",
            partial: "exams/registration_tab_label",
            locals: { exam: exam }
          ),
          stream_flash
        ].compact, status: status
      end

      def exam_with_campaign_errors
        exam = @campaign.exam
        exam.load_registration_deadline
        exam.reopen_after_deadline_fix = true
        exam.registration_deadline = params[:registration_deadline].presence ||
                                     @campaign.registration_deadline

        @campaign.errors.each do |error|
          next unless error.attribute == :registration_deadline

          exam.errors.add(:registration_deadline, error.type, **error.options)
        end

        exam
      end
  end
end
