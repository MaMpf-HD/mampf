module Vignettes
  class InfoSlidesController < ApplicationController
    before_action :set_questionnaire
    before_action :set_info_slide, only: [:edit, :update]
    before_action :check_empty_title, only: [:create, :update]
    before_action :check_empty_icon, only: [:create, :update]

    def new
      @info_slide = InfoSlide.new

      return unless request.xhr?

      render partial: "vignettes/questionnaires/slide_accordion_item",
             locals: { slide: @info_slide }
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

    def edit
      render partial: "vignettes/info_slides/form" if request.xhr?
    end

    def update
      if @info_slide.update(info_slide_params)
        redirect_to edit_questionnaire_path(@questionnaire),
                    notice: t("vignettes.info_slide_updated")
      elsif request.xhr?
        render partial: "vignettes/info_slides/form"
      else
        redirect_to edit_questionnaire_path(@questionnaire),
                    alert: t("vignettes.info_slide_not_updated")
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
        params.require(:vignettes_info_slide).permit(:title, :content, :icon_type)
      end
  end
end
