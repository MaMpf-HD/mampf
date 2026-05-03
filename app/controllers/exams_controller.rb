class ExamsController < ApplicationController
  include Flash

  before_action :set_lecture, only: [:index, :new]
  before_action :set_exam, only: [:show, :edit, :update, :destroy,
                                  :add_participant, :remove_participant]
  authorize_resource except: :index

  def current_ability
    @current_ability ||= ExamAbility.new(current_user)
  end

  def index
    authorize! :index, Exam.new(lecture: @lecture)
    set_exam_locale
    @exams = @lecture.exams.order(date: :asc)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("exams_container",
                                                 partial: "exams/list",
                                                 locals: { lecture: @lecture,
                                                           exams: @exams })
      end
    end
  end

  def show
    authorize! :show, @exam
    @active_tab = params[:tab] || "settings"
    set_exam_locale

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "exams_container",
          build_dashboard_component
        )
      end
    end
  end

  def new
    @exam = Exam.new
    @exam.lecture = @lecture
    authorize! :new, @exam
    set_exam_locale

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("exams_container",
                                                 partial: "exams/settings",
                                                 locals: { exam: @exam,
                                                           lecture: @lecture })
      end
    end
  end

  def edit
    authorize! :edit, @exam

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("exams_container",
                                                 partial: "exams/form",
                                                 locals: { exam: @exam,
                                                           lecture: @lecture })
      end
    end
  end

  def create
    @exam = Exam.new(exam_params)
    @lecture = @exam.lecture
    authorize! :create, @exam
    set_exam_locale

    respond_to do |format|
      if @exam.save
        @exam.load_registration_deadline
        format.turbo_stream do
          flash[:success] = t("assessment.exam_created")
          @active_tab = "settings"
          streams = [
            turbo_stream.update("exams_container",
                                build_dashboard_component),
            stream_flash
          ]
          render turbo_stream: streams
        end
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("exams_container",
                                                   partial: "exams/settings",
                                                   locals: { exam: @exam,
                                                             lecture: @lecture }),
                 status: :unprocessable_content
        end
      end
    end
  end

  def update
    authorize! :update, @exam
    reopen_after_deadline_fix = params[:reopen_after_deadline_fix].present?
    update_params = exam_update_params(reopen_after_deadline_fix: reopen_after_deadline_fix)

    respond_to do |format|
      if @exam.update(update_params)
        reopen_exam_campaign_after_deadline_fix if reopen_after_deadline_fix
        @exam.load_registration_deadline
        format.turbo_stream do
          flash[:success] = if reopen_after_deadline_fix
            t("registration.campaign.reopened")
          else
            t("assessment.exam_updated")
          end
          if ["settings", "registration"].include?(params[:tab])
            render turbo_stream: [
              turbo_stream.update(
                "exams_container",
                build_dashboard_component(active_tab: params[:tab])
              ),
              stream_flash
            ]
          else
            streams = [
              turbo_stream.update("exams_container",
                                  partial: "exams/list",
                                  locals: { lecture: @lecture,
                                            exams: @lecture.exams.order(date: :asc) }),
              stream_flash
            ]
            render turbo_stream: streams
          end
        end
      else
        format.turbo_stream do
          @exam.reopen_after_deadline_fix = params[:reopen_after_deadline_fix].present?
          if ["settings", "registration"].include?(params[:tab])
            render turbo_stream: turbo_stream.update(
              "exams_container",
              build_dashboard_component(active_tab: params[:tab])
            ), status: :unprocessable_content
          else
            render turbo_stream: turbo_stream.update("exams_container",
                                                     partial: "exams/form",
                                                     locals: { exam: @exam,
                                                               lecture: @lecture }),
                   status: :unprocessable_content
          end
        end
      end
    end
  end

  def destroy
    authorize! :destroy, @exam

    if @exam.destructible?
      @exam.destroy
      respond_to do |format|
        format.turbo_stream do
          flash[:success] = t("assessment.exam_destroyed")
          render turbo_stream: [
            turbo_stream.update("exams_container",
                                partial: "exams/list",
                                locals: { lecture: @lecture,
                                          exams: @lecture.exams.order(date: :asc) }),
            stream_flash
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          reason = @exam.non_destructible_reason
          flash[:error] = t("assessment.exam_not_destructible.#{reason}")
          render turbo_stream: stream_flash,
                 status: :unprocessable_content
        end
      end
    end
  end

  def add_participant
    authorize! :add_participant, @exam
    user = participant_user

    respond_to do |format|
      format.turbo_stream do
        if user.nil?
          flash.now[:error] = t("assessment.registration_tab.user_not_found")
        else
          service = Rosters::MaintenanceService.new
          begin
            service.add_user!(user, @exam, force: true)
            flash.now[:success] = t("assessment.registration_tab.participant_added",
                                    name: user.tutorial_name.presence || user.email)
          rescue ActiveRecord::RecordInvalid
            flash.now[:error] = t("assessment.registration_tab.already_registered")
          end
        end
        @active_tab = "registration"
        render turbo_stream: [
          turbo_stream.update("exams_container", build_dashboard_component),
          stream_flash
        ]
      end
    end
  end

  def remove_participant
    authorize! :remove_participant, @exam
    user = User.find(params[:user_id])
    Rosters::MaintenanceService.new.remove_user!(user, @exam)

    respond_to do |format|
      format.turbo_stream do
        flash.now[:success] = t("assessment.registration_tab.participant_removed",
                                name: user.tutorial_name.presence || user.email)
        @active_tab = "registration"
        render turbo_stream: [
          turbo_stream.update("exams_container", build_dashboard_component),
          stream_flash
        ]
      end
    end
  end

  private

    def participant_user
      return User.find_by(id: params[:user_id]) if params[:user_id].present?

      User.find_by(email: params[:email]&.strip)
    end

    def set_exam
      @exam = Exam.find(params[:id])
      @exam.load_registration_deadline
      @lecture = @exam.lecture
      set_exam_locale
    end

    def set_lecture
      @lecture = Lecture.find_by(id: params[:lecture_id])
      return if @lecture

      redirect_to root_path, alert: I18n.t("controllers.no_lecture")
    end

    def set_exam_locale
      I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
    end

    def exam_params
      params.expect(exam: [:title, :date, :location, :capacity,
                           :description, :skip_campaigns,
                           :registration_deadline,
                           :lecture_id])
    end

    def exam_update_params(reopen_after_deadline_fix: false)
      permitted = exam_params
      return permitted if deadline_editable?(reopen_after_deadline_fix: reopen_after_deadline_fix)

      permitted.except(:registration_deadline)
    end

    def deadline_editable?(reopen_after_deadline_fix: false)
      return true if reopen_after_deadline_fix

      campaign = @exam.registration_campaign
      campaign && (campaign.draft? || campaign.open?)
    end

    def build_dashboard_component(active_tab: @active_tab, task: nil)
      assessment = @exam.assessment
      tasks = assessment&.tasks&.order(:position) || []
      AssessmentDashboardComponent.new(
        assessable: @exam,
        assessment: assessment,
        lecture: @lecture,
        active_tab: active_tab,
        tasks: tasks,
        task: task
      )
    end

    def reopen_exam_campaign_after_deadline_fix
      campaign = @exam.registration_campaign
      return unless campaign && !campaign.completed?

      campaign.reopen!(registration_deadline: @exam.registration_deadline)
    end
end
