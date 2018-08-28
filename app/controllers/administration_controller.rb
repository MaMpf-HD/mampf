# AdministrationController
class AdministrationController < ApplicationController
  authorize_resource class: false
  def index
  end

  def exit
    redirect_to :root
  end

  def profile
  end
end
