class Api::V1::MediaController < ApplicationController
  respond_to :json
  def keks_question
    @medium = Medium.KeksQuestion.find_by(question_id: params[:id])
    if @medium != nil then
      width = params[:width].to_i
      aspect_ratio = @medium.width.to_f / @medium.height
      height = (width.to_i/aspect_ratio).to_i.to_s
      render json: { medium: MediumSerializer.new(@medium),
                     embedded_video:
                       render_to_string(partial: 'shared/video',
                                        formats: :html,
                                        layout: false,
                                        locals: { medium: @medium, width: width,
                                                  height: height}) }
    else
      render json: { medium: {}, embedded_video: ''}
    end
  end
end
