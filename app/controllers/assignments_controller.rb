# AssignmentsController
class AssignmentsController < ApplicationController
  before_action :set_assignment, except: [:new, :cancel_new, :create]
  before_action :set_lecture, only: :create
  authorize_resource except: [:new, :cancel_new, :create]

  def current_ability
    @current_ability ||= AssignmentAbility.new(current_user)
  end

  def new
    @assignment = Assignment.new
    @lecture = Lecture.find_by_id(params[:lecture_id])
    @assignment.lecture = @lecture
    authorize! :new, @assignment
    set_assignment_locale
  end

  def create
    @assignment = Assignment.new(assignment_params)
    authorize! :create, @assignment
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
    assignment = Assignment.new(lecture: @lecture)
    authorize! :cancel_new, assignment
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
end