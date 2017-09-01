class Api::V1::MediumController < ApplicationController
  respond_to :json
  def keks_question
    @medium = Medium.KeksQuestion.where(question_id: params[:id])
    render :json => @medium
  end
end
