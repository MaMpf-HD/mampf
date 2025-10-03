module Vignettes
  class InfoSlidesController < ApplicationController
    before_action :set_questionnaire
    before_action :set_info_slide, only: [:edit, :update]
    before_action :check_empty_title, only: [:create, :update]
    before_action :check_empty_icon, only: [:create, :update]
    before_action :require_turbo_frame, only: [:new, :edit, :update]

    def new
      @info_slide = InfoSlide.new

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            :info_slides,
            partial: "vignettes/questionnaires/shared/slide_accordion_item",
            locals: { slide: @info_slide }
          )
        end
      end
    end

    def edit
      render partial: "vignettes/info_slides/form/form"
    end

    def create
      @info_slide = @questionnaire.info_slides.new(info_slide_params)
      if @info_slide.save
        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.info_slide_created")
      else
        render :new
      end
    end

    def update
      if @info_slide.update(info_slide_params)
        render partial: "vignettes/info_slides/form/form"
      else
        respond_with_flash(:alert, t("vignettes.info_slide_not_updated"),
                           fallback_location: edit_questionnaire_path(@questionnaire))
      end
    end

    def destroy
      unless @questionnaire.editable
        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.info_slide_not_deleted")
        return
      end

      @info_slide = @questionnaire.info_slides.find(params[:id])

      begin
        ActiveRecord::Base.transaction do
          # Remove associations with slides before destroying
          @info_slide.slides.clear

          @info_slide.destroy
        end

        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.info_slide_deleted")
      rescue StandardError => e
        Rails.logger.error("Error deleting info slide: #{e.message}")
        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.info_slide_not_deleted")
      end
    end

    private

      def check_empty_title
        return if info_slide_params[:title].present? && info_slide_params[:title].length.positive?

        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.info_slide_empty_title")
      end

      def check_empty_icon
        if info_slide_params[:icon_type].present? && info_slide_params[:icon_type].length.positive?
          return
        end

        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.info_slide_empty_icon")
      end

      def set_questionnaire
        @questionnaire = Questionnaire.find(params[:questionnaire_id])
      end

      def set_info_slide
        @info_slide = @questionnaire.info_slides.find(params[:id])
      end

      def info_slide_params
        params.expect(vignettes_info_slide: [:title, :content, :icon_type])
      end
  end
end
