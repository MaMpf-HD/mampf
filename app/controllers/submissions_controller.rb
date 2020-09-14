# SubmissionsController
class SubmissionsController < ApplicationController
  before_action :set_submission, only: [:destroy]

  def index
    @lecture = Lecture.find_by_id(params[:lecture_id])
    @assignments = @lecture.assignments.order(:deadline)
  end

  def new
  	@submission = Submission.new
  	@assignment = Assignment.find_by_id(params[:assignment])
  	@lecture = @assignment.lecture
  end

  def create
  	@submission = Submission.new(submission_params)
    @submission.users << current_user
    @submission.save
    @assignment = @submission.assignment
  end

  def destroy
    @assignment = @submission.assignment
    @submission.destroy
  end

  private

  def set_submission
    @submission = Submission.find_by_id(params[:id])
    return if @submission
    redirect_to :root, alert: I18n.t('controllers.no_submission')
  end

  def submission_params
    params.require(:submission).permit(:tutorial_id, :assignment_id)
  end
end