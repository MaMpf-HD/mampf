# AdministrationController
class AdministrationController < ApplicationController
  authorize_resource :class => false
  def index
    cookies[:administrates] = 'true'
  end

  def exit
    cookies[:administrates] = 'false'
    redirect_to :root
  end
end
