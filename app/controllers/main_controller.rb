class MainController < ApplicationController
  skip_before_action :authenticate_user!, :only => [:home, :about]

  def home
  end

  def about
  end

  def error
    redirect_to :root, alert: 'Die angeforderte Seit existiert nicht. Du wurdest auf die MaMpf-Homepage umgeleitet.'
  end
end
