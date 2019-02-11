# MediaController for API
class Api::V1::MediaController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :json

  # example call: /api/v1/keks_questions/310
  def keks_question
    # find medium of sort keks question, whose question id is the one given
    # as parameter
    @medium = Medium.where(sort: 'KeksQuestion')
                    .find { |m| m.question_id == params[:id].to_i }
    width = params[:width].to_i
    if @medium.present?
      render json:
        {
          medium: MediumSerializer.new(@medium),
          embedded_video:
            render_to_string(partial: 'api/v1/medium/video',
                             formats: :html,
                             layout: false,
                             locals:
                               { medium: @medium,
                                 width: width,
                                 height: @medium.video_scaled_height(width) })
        }
    else
      # render trivial json
      render json: { medium: {}, embedded_video: '' }
    end
  end
end
