class Api::V1::MediaController < ApplicationController
  respond_to :json
  def keks_question
    @medium = Medium.KeksQuestion.find_by(question_id: params[:id])
    width = params[:width].to_i
    if !@medium.nil?
      render json:
        {
          medium: MediumSerializer.new(@medium),
          embedded_video:
            render_to_string(partial: 'shared/video',
                             formats: :html,
                             layout: false,
                             locals:
                               { medium: @medium,
                                 width: width,
                                 height: @medium.video_scaled_height(width) })
        }
    else
      render json: { medium: {}, embedded_video: '' }
    end
  end
end
