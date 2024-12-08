module Vignettes
  class QuestionnairesController < ApplicationController
    def index
      @questionnaires = Questionnaire.all
      # Because the create model form works on the index page.
      @questionnaire = Questionnaire.new
    end

    def show
      @questionnaire = Questionnaire.find(params[:id])
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
    end

    private

      def questionnaire_params
        params.require(:vignettes_questionnaire).permit(:title)
      end
  end
end
