# AdministrationController
class AdministrationController < ApplicationController
  authorize_resource class: false
  def index
  end

  def exit
  	course_id = cookies[:current_course]
    redirect_to course_path(course_id)
  end

  def profile
  end
end
