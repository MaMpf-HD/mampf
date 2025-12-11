class AltchaController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    ip = request.remote_ip
    key = "altcha_rate_limit:#{ip}"
    count = Rails.cache.read(key) || 0

    if count.to_i >= 15
      render json: { error: "Rate limit exceeded" }, status: :too_many_requests
      return
    end

    Rails.cache.write(key, count.to_i + 1, expires_in: 2.minutes)
    render json: Altcha::Challenge.create.to_json
  end
end
