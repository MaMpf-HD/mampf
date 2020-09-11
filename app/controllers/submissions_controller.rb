# SubmissionsController
class SubmissionsController < ApplicationController

  def index
    @lecture = Lecture.find_by_id(params[:lecture_id])
  end
end