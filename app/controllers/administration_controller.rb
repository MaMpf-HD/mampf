# AdministrationController
class AdministrationController < ApplicationController
  authorize_resource class: false
  def index
  end

  def exit
  	course_id = cookies[:current_course]
  	if course_id.present?
  	  redirect_to course_path(course_id)
 			return
 		end
 		redirect_to root_path
  end

  def profile
  end
end
