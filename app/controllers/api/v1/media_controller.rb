# MediaController for API
# 2019-04-18: API is deprecated
class Api::V1::MediaController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :json

  # example call: /api/v1/keks_questions/310
  def keks_question
    # render trivial json
    render json: { medium: {}, embedded_video: '' }
  end
end
