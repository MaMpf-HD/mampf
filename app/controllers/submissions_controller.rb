# SubmissionsController
class SubmissionsController < ApplicationController

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
  	@assignment = Assignment.find_by_id(params[:assignment])
  	return unless @assignment
  end
end