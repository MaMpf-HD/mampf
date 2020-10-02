# TutorialsController
class TutorialsController < ApplicationController
  before_action :set_tutorial, only: [:edit, :destroy, :update, :cancel_edit]
  before_action :set_lecture, only: [:index, :overview]
  before_action :check_tutor_status, only: :index
  before_action :check_editor_status, only: :overview
  authorize_resource

  def index
    @assignments = @lecture.assignments.expired.order('deadline DESC')
    @assignment = Assignment.find_by_id(params[:assignment]) ||
                    @assignments&.first
    @tutorials = current_user.given_tutorials.where(lecture: @lecture)
                             .order(:title)
    @tutorial = Tutorial.find_by_id(params[:tutorial]) || @tutorials.first
    @stack = @assignment.submissions.where(tutorial: @tutorial)
  end

  def overview
    @assignments = @lecture.assignments.expired.order('deadline DESC')
    @assignment = Assignment.find_by_id(params[:assignment]) ||
                    @assignments&.first
  end

  def new
    @tutorial = Tutorial.new
    lecture = Lecture.find_by_id(params[:lecture_id])
    @tutorial.lecture = lecture
  end

  def create
    @tutorial = Tutorial.new(tutorial_params)
    @tutorial.save
    @errors = @tutorial.errors
  end

  def edit
  end

  def update
    @tutorial.update(tutorial_params)
    @errors = @tutorial.errors
    return if @errors.present?
    @tutorial.update(tutor: nil) if tutorial_params[:tutor_id].blank?
  end

  def destroy
    @lecture = @tutorial.lecture
    @tutorial.destroy
  end

  def cancel_edit
  end

  def cancel_new
    @lecture = Lecture.find_by_id(params[:lecture])
    @none_left = @lecture&.tutorials&.none?
  end

  private

  def set_tutorial
    @tutorial = Tutorial.find_by_id(params[:id])
    return if @tutorial
    redirect_to :root, alert: I18n.t('controllers.no_tutorial')
  end

  def set_lecture
    @lecture = Lecture.find_by_id(params[:id])
    return if @lecture
    redirect_to :root, alert: I18n.t('controllers.no_lecture')
  end

  def check_tutor_status
    return if current_user.in?(@lecture.tutors)
    redirect_to :root, alert: I18n.t('controllers.no_tutor_in_this_lecture')
  end

  def check_editor_status
    return if current_user.editor_or_teacher_in?(@lecture)
    redirect_to :root, alert: I18n.t('controllers.no_editor_or_teacher')
  end

  def tutorial_params
    params.require(:tutorial).permit(:title, :tutor_id, :lecture_id)
  end
end