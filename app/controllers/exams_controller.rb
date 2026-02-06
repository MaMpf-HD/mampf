class ExamsController < ApplicationController
  include Flash

  before_action :set_lecture, only: [:index, :new]
  before_action :set_exam, only: [:edit, :update, :destroy]
  authorize_resource except: :index

  def current_ability
    @current_ability ||= ExamAbility.new(current_user)
  end

  def index
    authorize! :index, Exam.new(lecture: @lecture)
    @exams = @lecture.exams.order(date: :desc)
    set_exam_locale

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("exams_container",
                                                 partial: "lectures/edit/exams",
                                                 locals: { lecture: @lecture })
      end
    end
  end

  def new
    @exam = Exam.new
    @exam.lecture = @lecture
    authorize! :new, @exam
    set_exam_locale

    respond_to do |format|
      format.js
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("exams_container",
                                                 partial: "exams/form",
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
          render turbo_stream: [
            turbo_stream.update("exams_container",
                                partial: "lectures/edit/exams",
                                locals: { lecture: @lecture }),
            stream_flash
          ]
        end
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("exams_container",
                                                   partial: "exams/form",
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
          render turbo_stream: [
            turbo_stream.update("exams_container",
                                partial: "lectures/edit/exams",
                                locals: { lecture: @lecture }),
            stream_flash
          ]
        end
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("exams_container",
                                                   partial: "exams/form",
                                                   locals: { exam: @exam,
                                                             lecture: @lecture }),
                 status: :unprocessable_content
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
            turbo_stream.remove("exam-row-#{@exam.id}"),
            stream_flash
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash[:error] = t("assessment.exam_not_destructible")
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
    end

    def set_exam_locale
      I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
    end

    def exam_params
      params.expect(exam: [:title, :date, :location, :capacity,
                           :description, :skip_campaigns,
                           :lecture_id])
    end
end
