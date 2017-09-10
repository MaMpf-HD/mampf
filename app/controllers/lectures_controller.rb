class LecturesController < ApplicationController
  before_action :authenticate_user!
  def show
  end

  def index
    @lectures = Lecture.all
  end
end
