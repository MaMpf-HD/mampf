# AdministrationController
# Controller for actions in administration mode (ie. for admins and editors)
# There is no model backing this controller.
class AdministrationController < ApplicationController
  # tell cancancan there is no model for this controller, but authorize
  # nevertheless
  authorize_resource class: false
  layout 'administration'

  def index
  end

  def exit
    redirect_to start_path
  end

  def profile
  end

  def classification
    @subjects = Subject.includes(programs: [:divisions]).all
  end

  def search
    @tags = params[:sort] == 'tag'
  end

  def log
    lines = params[:lines]
    @logs = `tail -n #{lines} log/emails.log`
  end
end
