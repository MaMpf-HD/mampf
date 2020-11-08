# AssignmentsController
class AssignmentsController < ApplicationController
  before_action :set_assignment, only: [:edit, :destroy, :update, :cancel_edit]
  before_action :set_lecture, only: :create
  before_action :check_editor_status, only: :create
  authorize_resource

  def new
    @assignment = Assignment.new
    @lecture = Lecture.find_by_id(params[:lecture_id])
    @assignment.lecture = @lecture
    set_assignment_locale
  end

  def create
    @assignment = Assignment.new(assignment_params)
    @assignment.save
    @errors = @assignment.errors
    @lecture = @assignment.lecture
    set_assignment_locale
  end

  def edit
  end

  def update
    @assignment.update(assignment_params)
    @errors = @assignment.errors
    return if @errors.present?
    @assignment.update(medium: nil) if assignment_params[:medium_id].blank?
  end

  def destroy
    @assignment.destroy
  end

  def cancel_edit
  end

  def cancel_new
    @lecture = Lecture.find_by_id(params[:lecture])
    set_assignment_locale
    @none_left = @lecture&.assignments&.none?
  end

  private

  def set_assignment
    @assignment = Assignment.find_by_id(params[:id])
    @lecture = @assignment&.lecture
    set_assignment_locale and return if @assignment
    redirect_to :root, alert: I18n.t('controllers.no_assignment')
  end

  def set_lecture
    @lecture = Lecture.find_by_id(assignment_params[:lecture_id])
    return if @lecture
    redirect_to :root, alert: I18n.t('controllers.no_lecture')
  end

  def set_assignment_locale
    I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
  end

  def assignment_params
    params.require(:assignment).permit(:title, :medium_id, :lecture_id,
                                       :deadline, :accepted_file_type)
  end

  def check_editor_status
    return if current_user.editor_or_teacher_in?(@lecture)
    redirect_to :root, alert: I18n.t('controllers.no_editor_or_teacher')
  end
end