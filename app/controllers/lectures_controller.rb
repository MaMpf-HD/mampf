class LecturesController < ApplicationController
  def show
  end

  def index
    @lectures = current_user.lectures
  end
end
