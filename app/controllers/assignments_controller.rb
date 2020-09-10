# AssignmentsController
class AssignmentsController < ApplicationController
  before_action :set_assignment, only: [:edit, :destroy, :update, :cancel_edit]
  # authorize_resource

  def new
    @assignment = Assignment.new
    lecture = Lecture.find_by_id(params[:lecture_id])
    @assignment.lecture = lecture
  end

  def create
    @assignment = Assignment.new(assignment_params)
    @assignment.save
    @errors = @assignment.errors
  end

  def edit
  end

  def update
    @assignment.update(assignment_params)
    @errors = @assignment.errors
  end

  def destroy
    @lecture = @assignment.lecture
    @assignment.destroy
  end

  def cancel_edit
  end

  def cancel_new
    @lecture = Lecture.find_by_id(params[:lecture])
    @none_left = @lecture&.assignments&.none?
  end

  private

  def set_assignment
    @assignment = Assignment.find_by_id(params[:id])
    return if @assignment
    redirect_to :root, alert: I18n.t('controllers.no_assignment')
  end

  def assignment_params
    params.require(:assignment).permit(:title, :medium_id, :lecture_id,
                                       :deadline)
  end
end