class AltchaController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    render json: Altcha::Challenge.create.to_json
  end
end
