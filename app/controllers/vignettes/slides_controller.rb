module Vignettes
  class SlidesController < ApplicationController
    before_action :set_questionnaire
    def index
    end

    def show
      @slide = @questionnaire.slides.find(params[:id])
    end

    def new
      @slide = @questionnaire.slides.new
    end

    def create
      @slide = @questionnaire.slides.new(slide_params)
      if @slide.save
        redirect_to @questionnaire, notice: "Slide was successfully created"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

      def set_questionnaire
        @questionnaire = Questionnaire.find(params[:questionnaire_id])
      end

      def slide_params
        params.require(:vignettes_slide).permit(:content)
      end
  end
end
