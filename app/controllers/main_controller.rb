# MainController
class MainController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :about, :news]
  before_action :check_for_consent

  def home
  end

  def about
    render layout: 'application_no_sidebar'
  end

  def error
    redirect_to :root, alert: 'Die angeforderte Seit existiert nicht. Du ' \
                              'wurdest auf die MaMpf-Homepage umgeleitet.'
  end

  def news
    @announcements = Announcement.where(lecture: nil).order(:created_at)
                                 .reverse
    render layout: 'application_no_sidebar'
  end

  private

  def check_for_consent
    return unless user_signed_in?
    redirect_to consent_profile_path unless current_user.consents
  end
end
