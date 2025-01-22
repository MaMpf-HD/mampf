module Vignettes
  class InfoSlidesController < ApplicationController
    before_action :set_questionnaire
    before_action :set_info_slide, only: [:edit, :update]

    def new
      @info_slide = InfoSlide.new
    end

    def create
      @info_slide = @questionnaire.info_slides.new(info_slide_params)
      if @info_slide.save
        redirect_to edit_vignettes_questionnaire_path(@questionnaire), notice: "Info slide created."
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @info_slide.update(info_slide_params)
        redirect_to edit_vignettes_questionnaire_path(@questionnaire), notice: "Info slide updated."
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

      def info_slide_params
        params.require(:vignettes_info_slide).permit(:title, :content)
      end
  end
end
