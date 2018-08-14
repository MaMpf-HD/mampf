# MainController
class MainController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :about]
  before_action :check_for_consent

  def home
  end

  def about
  end

  def error
    redirect_to :root, alert: 'Die angeforderte Seit existiert nicht. Du ' \
                              'wurdest auf die MaMpf-Homepage umgeleitet.'
  end

  private

  def check_for_consent
    return unless user_signed_in?
    redirect_to consent_profile_path unless current_user.consents
  end
end
