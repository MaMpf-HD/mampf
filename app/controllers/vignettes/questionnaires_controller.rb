module Vignettes
  class QuestionnairesController < ApplicationController
    before_action :set_questionnaire,
                  only: [:take, :preview, :submit_answer, :edit, :publish, :export_answers,
                         :update_slide_position, :destroy, :duplicate]
    before_action :set_lecture, only: [:index, :new, :create]
    before_action :check_take_accessibility, only: [:take, :submit_answer]
    before_action :check_edit_accessibility,
                  only: [:edit, :preview, :destroy, :publish, :update_slide_position, :duplicate]
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

    def preview
      @preview = true
      @position =
        if params[:start].present?
          params[:start].to_i
        elsif params[:position].present?
          params[:position].to_i
        else
          1
        end

      if @position > @questionnaire.slides.maximum(:position) || @position < 1
        redirect_to edit_questionnaire_path(@questionnaire)
        return
      end

      @slide = @questionnaire.slides.find_by(position: @position)

      render :take, layout: "application_no_sidebar"
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
      if @questionnaire.update(published: true)
        redirect_to edit_questionnaire_path(@questionnaire), notice: t("vignettes.published")
      else
        redirect_to edit_questionnaire_path(@questionnaire), alert: t("vignettes.not_published")
      end
    end

    def update_slide_position
      if @questionnaire.published
        render json: { error: t("vignettes.not_editable") }, status: :unprocessable_entity
        return
      end
      old_position = params[:old_position].to_i + 1
      new_position = params[:new_position].to_i + 1

      @slide = @questionnaire.slides.find_by(position: old_position)

      if new_position < 1 || new_position > @questionnaire.slides.maximum(:position)
        render json: { error: "Invalid position" }, status: :unprocessable_entity
        return
      end

      # rubocop:disable Rails/SkipsModelValidations
      ActiveRecord::Base.transaction do
        @slide.update!(position: -1)
        if new_position > old_position
          @questionnaire.slides.where("position > ? AND position <= ?", old_position, new_position)
                        .update_all("position = position - 1")
        else
          @questionnaire.slides.where("position < ? AND position >= ?", old_position, new_position)
                        .update_all("position = position + 1")
        end

        @slide.update!(position: new_position)
      end
      # rubocop:enable Rails/SkipsModelValidations

      render json: { success: true }
    rescue StandardError => e
      Rails.logger.error("Slide position update failed: #{e.message}")
      render json: { error: e.message }, status: :unprocessable_entity
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

    def destroy
      @lecture = @questionnaire.lecture
      if @questionnaire.destroy
        redirect_to edit_lecture_path(@lecture),
                    notice: t("vignettes.questionnaire_deleted")
      else
        redirect_to edit_lecture_path(@lecture),
                    alert: t("vignettes.questionnaire_not_deleted")
      end
    end

    def duplicate
      ActiveRecord::Base.transaction do
        new_title = params[:title].presence || "Copy of #{@questionnaire.title}"
        new_questionnaire = @questionnaire.dup
        new_questionnaire.title = new_title
        new_questionnaire.published = false
        new_questionnaire.save!

        # Update lecture cache to show the new questionnaire
        @questionnaire.lecture.touch

        # Duplicate slides
        @questionnaire.slides.order(:position).each do |slide|
          new_slide = slide.dup
          new_slide.content = slide.content
          new_slide.questionnaire = new_questionnaire
          new_slide.save!

          new_question = slide.question.dup
          new_question.slide = new_slide
          new_question.save!

          next unless slide.question.type == "Vignettes::MultipleChoiceQuestion"

          slide.question.options.each do |option|
            new_option = option.dup
            new_option.question = new_question
            new_option.save!
          end
        end

        redirect_to edit_lecture_path(@questionnaire.lecture),
                    notice: t("vignettes.questionnaire_duplicated")
      end
    rescue StandardError => e
      Rails.logger.error("Failed to duplicate questionnaire: #{e.message}")
      redirect_to edit_questionnaire_path(@questionnaire),
                  alert: t("vignettes.questionnaire_not_duplicated")
    end

    private

      def set_questionnaire
        if Questionnaire.exists?(params[:id])
          @questionnaire = Questionnaire.find(params[:id])
          return
        end

        redirect_to :root, alert: t("vignettes.not_found")
      end

      def set_lecture
        if Lecture.exists?(params[:lecture_id])
          @lecture = Lecture.find(params[:lecture_id])
          if @lecture.sort != "vignettes"
            redirect_to :root, alert: t("vignettes.not_vignettes_lecture")
          end
          return
        end

        redirect_to :root, alert: t("vignettes.no_lecture")
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
                       :time_on_info_slides, :info_slides_access_count,
                       :info_slides_first_access_time])
      end
  end
end
