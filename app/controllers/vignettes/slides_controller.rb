module Vignettes
  class SlidesController < ApplicationController
    before_action :set_questionnaire
    before_action :check_edit_accessibility, only: [:new, :create, :edit, :update, :destroy]
    before_action :check_empty_multiple_choice_option, only: [:update, :create]

    def new
      return unless @questionnaire.editable

      @slide = @questionnaire.slides.new
      @slide.build_question
      @slide.question.options.build

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            :slides,
            partial: "vignettes/questionnaires/shared/slide_accordion_item",
            locals: { slide: @slide }
          )
        end
      end
    end

    def edit
      @slide = @questionnaire.slides.find(params[:id])
      @slide.build_question unless @slide.question
      @slide.question.options.build unless @slide.question.options.any?

      render partial: "vignettes/slides/form/form"
    end

    def create
      @slide = @questionnaire.slides.new(slide_params)
      @slide.position = @questionnaire.slides.maximum(:position).to_i + 1
      if @slide.save
        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.slide_created")
      else
        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.slide_not_created")
      end
    end

    def update
      @slide = @questionnaire.slides.find(params[:id])

      if !@questionnaire.editable &&
         ((slide_params.dig(:question_attributes, :type).present? &&
          slide_params.dig(:question_attributes, :type) != @slide.question.type) ||
          slide_params.dig(:question_attributes, :options_attributes).present? ||
          slide_params.dig(:question_attributes, :language).present? ||
          slide_params[:title].present? ||
          slide_params[:info_slide_ids].present? ||
          any_option_deleted?)
        return redirect_to edit_questionnaire_path(@questionnaire),
                           alert: t("vignettes.not_editable")
      end

      if @slide.update(slide_params)
        render partial: "vignettes/slides/form/form"
      else
        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.slide_not_updated")
      end
    end

    def destroy
      unless @questionnaire.editable
        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.slide_not_deleted")
      end
      @slide = @questionnaire.slides.find(params[:id])
      position = @slide.position

      # rubocop:disable Rails/SkipsModelValidations
      begin
        ActiveRecord::Base.transaction do
          @slide.destroy

          @questionnaire.slides.where("position > ?",
                                      position).update_all("position = position - 1")
        end

        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.slide_deleted")
      rescue StandardError => _e
        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.slide_not_deleted")
      end
      # rubocop:enable Rails/SkipsModelValidations
    end

    private

      def any_option_deleted?
        options = slide_params.dig(:question_attributes, :options_attributes)
        return false unless options

        option_destroyed = false
        options.each_value do |v|
          option_destroyed = true if v[:_destroy] == "1"
        end

        option_destroyed
      end

      def set_questionnaire
        @questionnaire = Questionnaire.find(params[:questionnaire_id])
      end

      def check_edit_accessibility
        return if current_user.admin
        return if current_user.in?(@questionnaire.lecture.editors_with_inheritance)

        redirect_to lecture_questionnaires_path(@questionnaire.lecture),
                    alert: t("vignettes.not_accessible")
      end

      def check_empty_multiple_choice_option
        return unless slide_params.present? &&
                      slide_params&.dig(:question_attributes,
                                        :type) == "Vignettes::MultipleChoiceQuestion"

        if slide_params.dig(:question_attributes, :options_attributes).empty?
          redirect_to edit_questionnaire_path(@questionnaire), alert: t("vignettes.no_option")
          return
        end

        exists_non_destroyed_option = false

        slide_params.dig(:question_attributes, :options_attributes).each_value do |option|
          exists_non_destroyed_option = true if option[:_destroy] == "false"
          next unless option[:_destroy] == "false"
          next unless option[:text].empty?

          redirect_to edit_questionnaire_path(@questionnaire), alert: t("vignettes.empty_option")
          break
        end

        return if exists_non_destroyed_option

        redirect_to edit_questionnaire_path(@questionnaire), alert: t("vignettes.no_option")
      end

      def redirect_params
        params.permit(:redirect_info_slide)
      end

      def slide_params
        params.expect(
          vignettes_slide: [:title,
                            :content,
                            :position,
                            { info_slide_ids: [],
                              question_attributes: [
                                :id,
                                :type,
                                :question_text,
                                :language,
                                :only_integer,
                                :min_number,
                                :max_number,
                                :_destroy,
                                { options_attributes: [[:id, :text, :_destroy]] }
                              ] }]
        )
      end
  end
end
