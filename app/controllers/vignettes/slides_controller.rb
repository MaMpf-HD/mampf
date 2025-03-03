module Vignettes
  class SlidesController < ApplicationController
    before_action :set_questionnaire
    before_action :check_edit_accessibility, only: [:new, :create, :edit, :update, :destroy]

    def new
      return if @questionnaire.published

      @slide = @questionnaire.slides.new
      @slide.build_question
      @slide.question.options.build

      return unless request.xhr?

      render partial: "vignettes/questionnaires/slide_accordion_item",
             locals: { slide: @slide }
    end

    def edit
      @slide = @questionnaire.slides.find(params[:id])
      @slide.build_question unless @slide.question
      @slide.question.options.build unless @slide.question.options.any?

      render partial: "vignettes/slides/form" if request.xhr?
    end

    def create
      @slide = @questionnaire.slides.new(slide_params)
      @slide.position = @questionnaire.slides.maximum(:position).to_i + 1
      if @slide.save
        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.slide_created")
      else
        flash[:alert] = "Failed to create slide: #{@slide.errors.full_messages.join(", ")}"
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @slide = @questionnaire.slides.find(params[:id])
      if @slide.update(slide_params)
        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.slide_updated")
      elsif request.xhr?
        render partial: "vignettes/slides/form"
      end
    end

    def destroy
      @slide = @questionnaire.slides.find(params[:id])
      position = @slide.position

      begin
        ActiveRecord::Base.transaction do
          @slide.destroy

          @questionnaire.slides.where("position > ?",
                                      position).update_all("position = position - 1")
        end

        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.slide_deleted")
      rescue StandardError => e
        Rails.logger.error("Slide deletion failed: #{e.message}")
        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.slide_not_deleted")
      end
    end

    private

      def set_questionnaire
        @questionnaire = Questionnaire.find(params[:questionnaire_id])
      end

      def check_edit_accessibility
        return if current_user.admin
        return if current_user.in?(@questionnaire.lecture.editors_with_inheritance)

        redirect_to lecture_questionnaires_path(@questionnaire.lecture),
                    alert: t("vignettes.not_accessible")
      end

      def redirect_params
        params.permit(:redirect_info_slide)
      end

      def slide_params
        params.require(:vignettes_slide).permit(
          :content,
          :position,
          { info_slide_ids: [] },
          question_attributes: [
            :id,
            :type,
            :question_text,
            :_destroy,
            { options_attributes: [:id, :text, :_destroy] }
          ]
        )
      end
  end
end
