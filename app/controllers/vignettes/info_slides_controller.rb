module Vignettes
  class InfoSlidesController < ApplicationController
    before_action :set_questionnaire
    before_action :set_info_slide, only: [:edit, :update]
    before_action :set_accepted_content_types, only: [:new, :edit]

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

    private

      def set_questionnaire
        @questionnaire = Questionnaire.find(params[:questionnaire_id])
      end

      def set_info_slide
        @info_slide = @questionnaire.info_slides.find(params[:id])
      end

      def set_accepted_content_types
        # TODO: Fix (Florian)
        # @accepted_content_types = InfoSlide::ACCEPTED_CONTENT_TYPES
        @accepted_content_types = nil
      end

      def info_slide_params
        params.require(:vignettes_info_slide).permit(:title, :content, :icon_type)
      end
  end
end
