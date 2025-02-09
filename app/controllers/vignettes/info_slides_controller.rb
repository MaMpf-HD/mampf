module Vignettes
  class InfoSlidesController < ApplicationController
    before_action :set_questionnaire
    before_action :set_info_slide, only: [:edit, :update]
    before_action :set_accepted_content_types, only: [:new, :edit]

    def new
      @info_slide = InfoSlide.new
    end

    def create
      @info_slide = @questionnaire.info_slides.new(info_slide_params)
      if @info_slide.save
        redirect_to edit_vignettes_questionnaire_path(@questionnaire),
                    notice: t("vignettes.info_slide_created")
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @info_slide.update(info_slide_params)
        redirect_to edit_vignettes_questionnaire_path(@questionnaire),
                    t("vignettes.info_slide_updated")
      else
        render :edit
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
        @accepted_content_types = InfoSlide::ACCEPTED_CONTENT_TYPES
      end

      def info_slide_params
        params.require(:vignettes_info_slide).permit(:title, :content, :icon)
      end
  end
end
