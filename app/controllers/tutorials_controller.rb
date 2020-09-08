# TutorialsController
class TutorialsController < ApplicationController
  before_action :set_tutorial, only: [:edit, :destroy, :update, :cancel_edit]
  authorize_resource

  def new
    @tutorial = Tutorial.new
    lecture = Lecture.find_by_id(params[:lecture_id])
    @tutorial.lecture = lecture
  end

  def create
    @tutorial = Tutorial.new(tutorial_params)
    @tutorial.save
  end

  def edit
  end

  def update
    @tutorial.update(tutorial_params)
  end

  def destroy
    @tutorial.destroy
  end

  def cancel_edit
  end

  private

  def set_tutorial
    @tutorial = Tutorial.find_by_id(params[:id])
    return if @tutorial.present?
    redirect_to :root, alert: I18n.t('controllers.no_tutorial')
  end

  def tutorial_params
    params.require(:tutorial).permit(:title, :tutor_id, :lecture_id)
  end
end