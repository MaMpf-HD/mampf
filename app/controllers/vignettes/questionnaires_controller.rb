require "csv"

module Vignettes
  class QuestionnairesController < ApplicationController
    before_action :set_questionnaire, only: [:show, :take, :submit_answer]
    def index
      @questionnaires = Questionnaire.all
      # Because the create model form works on the index page.
      @questionnaire = Questionnaire.new
    end

    def show
      redirect_to edit_vignettes_questionnaire_path
    end

    def take
      user_answer = current_user.vignettes_user_answers
                                .find_or_create_by(user: current_user,
                                                   questionnaire: @questionnaire)

      if params[:position].to_i == -1
        # ONLY FOR DEBUG
        user_answer.destroy
        redirect_to vignettes_questionnaire_path, notice: t("vignettes.destroy_answer")
        return
      end

      # Vignettes was already fully answered by user
      if user_answer.last_slide_answered?
        redirect_to vignettes_questionnaire_path, notice: t("vignettes.answered")
        return
      end

      first_unanswered_slide = user_answer.first_unanswered_slide
      # This case should never happen
      if first_unanswered_slide.nil?
        redirect_to vignettes_questionnaire_path, notice: t("vignettes.no_slides")
        return
      end

      requested_position = params[:position].to_i

      # If there is no position given or the requested position is invalid
      if requested_position.zero? || requested_position != first_unanswered_slide.position
        redirect_to vignettes_take_questionnaire_path(@questionnaire,
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
      @answer = @slide.answers.build(answer_params.except(:slide_id))
      @answer.question = @slide.question
      @answer.type = @slide.question.type.gsub("Question", "Answer")
      @user_answer = current_user.vignettes_user_answers.find_by(user: current_user,
                                                                 questionnaire: @questionnaire)
      @answer.user_answer = @user_answer

      if @answer.save
        redirect_to vignettes_take_questionnaire_path(@questionnaire, position: @slide.position + 1)
      else
        Rails.logger.debug { "Answer save failed: #{@answer.errors.full_messages.join(", ")}" }
        render :take, status: :unprocessable_entity
      end
    end

    def export_answers
      questionnaire = Questionnaire.find(params[:id])
      answers = questionnaire.slides.includes(:answers).flat_map(&:answers)

      csv_data = CSV.generate(headers: true) do |csv|
        csv << ["Answer ID", "User", "Question Slide", "Time on slide", "Time on info slide",
                "Info slide accessed", "Question Text", "Answer", "Selected Options"]
        answers.each do |answer|
          row = [answer.id, answer.user_answer.user.name_or_email, answer.slide.position,
                 answer.slide_statistic.time_on_slide, answer.slide_statistic.time_on_info_slides,
                 answer.slide_statistic.info_slides_access_count,
                 answer.slide.question.question_text]
          case answer.type
          when "Vignettes::TextAnswer"
            row << answer.text
          when "Vignettes::MultipleChoiceAnswer"
            selected_options = answer.options.map(&:text).join(", ")
            row << ""
            row << selected_options
          end
          csv << row
        end
      end

      send_data(csv_data, filename: "questionnaire-#{questionnaire.id}-answers.csv")
    end

    def new
      @questionnaire = Questionnaire.new
    end

    def create
      @questionnaire = Questionnaire.new(questionnaire_params)
      if @questionnaire.save
        redirect_to @questionnaire
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @questionnaire = Questionnaire.find(params[:id])
      @slides = @questionnaire.slides.order(:position)
    end

    private

      def set_questionnaire
        @questionnaire = Questionnaire.find(params[:id])
      end

      def questionnaire_params
        params.require(:vignettes_questionnaire).permit(:title)
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
