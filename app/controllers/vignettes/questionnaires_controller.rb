module Vignettes
  class QuestionnairesController < ApplicationController
    before_action :set_questionnaire,
                  only: [:show, :take, :submit_answer, :edit, :publish, :export_answers]
    before_action :set_lecture, only: [:index, :new, :create]
    before_action :check_take_accessibility, only: [:take, :submit_answer]
    before_action :check_edit_accessibility, only: [:edit, :destroy, :publish]
    before_action :check_empty, only: [:publish, :take, :submit_answer]
    def index
      @questionnaires = @lecture.vignettes_questionnaires
      # Because the create model form works on the index page.
      @questionnaire = Questionnaire.new
    end

    def take
      user_answer = current_user.vignettes_user_answers
                                .find_or_create_by(user: current_user,
                                                   questionnaire: @questionnaire)

      if params[:position].to_i == -1
        # ONLY FOR DEBUG
        user_answer.destroy
        redirect_to lecture_questionnaires_path(@questionnaire.lecture),
                    notice: t("vignettes.destroy_answer")
        return
      end

      # Vignettes was already fully answered by user
      if user_answer.last_slide_answered?
        redirect_to lecture_questionnaires_path(@questionnaire.lecture),
                    notice: t("vignettes.answered")
        return
      end

      first_unanswered_slide = user_answer.first_unanswered_slide
      # This case should never happen
      if first_unanswered_slide.nil?
        redirect_to lecture_questionnaires_path(@questionnaire.lecture),
                    notice: t("vignettes.no_slides")
        return
      end

      requested_position = params[:position].to_i

      # If there is no position given or the requested position is invalid
      if requested_position.zero? || requested_position != first_unanswered_slide.position
        redirect_to take_questionnaire_path(@questionnaire,
                                            position: first_unanswered_slide.position)
        return
      end

      @slide = @questionnaire.slides.find_by(position: requested_position)
      @answer = @slide.answers.build
      @answer.build_slide_statistic

      render layout: "application_no_sidebar"
    end

    def submit_answer
      @slide = @questionnaire.slides.find(answer_params[:slide_id])
      @answer = @slide.answers.build
      @answer.question = @slide.question
      @answer.type = @slide.question.type.gsub("Question", "Answer")
      @user_answer = current_user.vignettes_user_answers.find_by(user: current_user,
                                                                 questionnaire: @questionnaire)
      @answer.user_answer = @user_answer
      @answer.assign_attributes(answer_params.except(:slide_id))

      if @answer.save
        redirect_to take_questionnaire_path(@questionnaire, position: @slide.position + 1)
      else
        Rails.logger.debug { "Answer save failed: #{@answer.errors.full_messages.join(", ")}" }
        render :take, status: :unprocessable_entity
      end
    end

    def publish
      if @questionnaire.update(published: !@questionnaire.published)
        redirect_to edit_questionnaire_path(@questionnaire), notice: t("vignettes.published")
      else
        redirect_to edit_questionnaire_path(@questionnaire), alert: t("vignettes.not_published")
      end
    end

    def export_answers
      csv_data = @questionnaire.answer_data_csv
      send_data(csv_data, filename: "questionnaire-#{@questionnaire.id}-answers.csv")
    end

    def new
      @questionnaire = Questionnaire.new
    end

    def create
      @questionnaire = Questionnaire.new(questionnaire_params)
      if @questionnaire.save
        redirect_to edit_questionnaire_path(@questionnaire)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @slides = @questionnaire.slides.order(:position)

      render layout: "application_no_sidebar"
    end

    private

      def set_questionnaire
        @questionnaire = Questionnaire.find(params[:id])
      end

      def set_lecture
        @lecture = Lecture.find(params[:lecture_id])
      end

      def check_take_accessibility
        return if @questionnaire.published &&
                  (current_user.admin || current_user.in?(@questionnaire.lecture.users))

        redirect_to lecture_questionnaires_path(@questionnaire.lecture),
                    alert: t("vignettes.not_accessible")
      end

      def check_edit_accessibility
        return if current_user.admin
        return if current_user.in?(@questionnaire.lecture.editors_with_inheritance)

        redirect_to lecture_questionnaires_path(@questionnaire.lecture),
                    alert: t("vignettes.not_accessible")
      end

      def check_empty
        return unless @questionnaire.slides.empty?

        redirect_to edit_questionnaire_path(@questionnaire), alert: t("vignettes.no_slides")
      end

      def questionnaire_params
        params.permit(:title, :lecture_id)
      end

      def answer_params
        params.require(:vignettes_answer)
              .permit(:slide_id, :text, :likert_scale_value,
                      option_ids: [],
                      slide_statistic_attributes:
                      [:user_id, :time_on_slide,
                       :time_on_info_slides, :info_slides_access_count])
      end
  end
end
