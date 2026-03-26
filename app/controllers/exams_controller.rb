class ExamsController < ApplicationController
  include Flash

  before_action :set_lecture, only: [:index, :new]
  before_action :set_exam, only: [:show, :edit, :update, :destroy]
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

    respond_to do |format|
      if @exam.update(exam_params)
        format.turbo_stream do
          flash[:success] = t("assessment.exam_updated")
          if params[:tab] == "settings"
            render turbo_stream: [
              turbo_stream.update(
                "exams_container",
                build_dashboard_component(active_tab: "settings")
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
          if params[:tab] == "settings"
            render turbo_stream: turbo_stream.update(
              "exams_container",
              build_dashboard_component(active_tab: "settings")
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

  private

    def set_exam
      @exam = Exam.find(params[:id])
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
end
