class ExamsController < ApplicationController
  before_action :set_lecture, only: [:index, :new]
  authorize_resource

  def current_ability
    @current_ability ||= ExamAbility.new(current_user)
  end

  def index
    @exams = @lecture.exams.order(date: :desc)
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
