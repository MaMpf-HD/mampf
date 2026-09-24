# Hands the sign-up captcha a fresh challenge each time it verifies, so the
# minutes a challenge lasts count from then, not from loading the page.
class CaptchaChallengesController < ApplicationController
  skip_before_action :store_user_location!
  skip_before_action :authenticate_user!

  def show
    response.headers["Cache-Control"] = "no-store"
    render json: Altcha.create_challenge
  end
end
