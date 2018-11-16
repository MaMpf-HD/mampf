# AdministrationController
# Controller for actions in administration mode (ie. for admins and editors)
# There is no model backing this controller.
class AdministrationController < ApplicationController
  # tell cancancan there is no model for this controller, but authorize
  # nevertheless
  authorize_resource class: false

  def index
  end

  def exit
    course_id = cookies[:current_course]
    # redirect to course view of the course that was selected
    # before admin mode was entered
    if course_id.present?
      redirect_to course_path(course_id)
      return
    end
    redirect_to root_path
  end

  def profile
  end
end
