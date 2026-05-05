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

    render turbo_stream: turbo_stream.update("exams_container",
                                             partial: "exams/list",
                                             locals: { lecture: @lecture,
                                                       exams: @exams })
  end

  def show
    authorize! :show, @exam

    render turbo_stream: turbo_stream.update("exams_container",
                                             partial: "exams/settings",
                                             locals: { exam: @exam,
                                                       lecture: @lecture })
  end

  def new
    @exam = Exam.new(lecture: @lecture)
    authorize! :new, @exam
    set_exam_locale

    render turbo_stream: turbo_stream.update("exams_container",
                                             partial: "exams/settings",
                                             locals: { exam: @exam,
                                                       lecture: @lecture })
  end

  def edit
    authorize! :edit, @exam

    render turbo_stream: turbo_stream.update("exams_container",
                                             partial: "exams/form",
                                             locals: { exam: @exam,
                                                       lecture: @lecture })
  end

  def create
    @exam = Exam.new(exam_params)
    @lecture = @exam.lecture
    authorize! :create, @exam
    set_exam_locale

    if @exam.save
      flash[:success] = t("assessment.exam_created")
      render turbo_stream: [
        turbo_stream.update("exams_container",
                            partial: "exams/settings",
                            locals: { exam: @exam, lecture: @lecture }),
        stream_flash
      ]
    else
      render turbo_stream: turbo_stream.update("exams_container",
                                               partial: "exams/settings",
                                               locals: { exam: @exam,
                                                         lecture: @lecture }),
             status: :unprocessable_content
    end
  end

  def update
    authorize! :update, @exam

    if @exam.update(exam_params)
      flash[:success] = t("assessment.exam_updated")
      render turbo_stream: [
        turbo_stream.update("exams_container",
                            partial: "exams/settings",
                            locals: { exam: @exam, lecture: @lecture }),
        stream_flash
      ]
    else
      render turbo_stream: turbo_stream.update("exams_container",
                                               partial: "exams/form",
                                               locals: { exam: @exam,
                                                         lecture: @lecture }),
             status: :unprocessable_content
    end
  end

  def destroy
    authorize! :destroy, @exam
    @exam.destroy
    flash[:success] = t("assessment.exam_destroyed")

    render turbo_stream: [
      turbo_stream.update("exams_container",
                          partial: "exams/list",
                          locals: { lecture: @lecture,
                                    exams: @lecture.exams.order(date: :asc) }),
      stream_flash
    ]
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
                           :description, :lecture_id])
    end
end