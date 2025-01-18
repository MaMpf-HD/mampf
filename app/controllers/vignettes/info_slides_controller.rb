module Vignettes
  class InfoSlidesController < ApplicationController
    before_action :set_slide

    def new
      @info_slide = InfoSlide.new
    end

    def create
      @info_slide = InfoSlide.new(info_slide_params)
      @info_slide.slides << @slide
      if @info_slide.save
        redirect_to edit_vignettes_questionnaire_slide_path(@slide.questionnaire, @slide),
                    notice: "Info slide created."
      else
        render :new
      end
    end

    def edit
      @info_slide = @slide.info_slide
    end

    def update
      @info_slide = @slide.info_slide
      if @info_slide.update(info_slide_params)
        redirect_to edit_vignettes_questionnaire_slide_path(@slide.questionnaire, @slide),
                    notice: "Info slide updated."
      else
        render :edit
      end
    end

    private

      def set_slide
        @slide = Slide.find(params[:slide_id])
      end

      def info_slide_params
        params.require(:vignettes_info_slide).permit(:content)
      end
  end
end
