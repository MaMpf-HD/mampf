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
    @lecture = Lecture.find_by(id: params[:lecture_id])
    @assignment.lecture = @lecture
    authorize! :new, @assignment
    set_assignment_locale

    respond_to do |format|
      format.js
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("assignment_form_container",
                                                 partial: "assessment/assignments/form",
                                                 locals: { assignment: @assignment })
      end
    end
  end

  def edit
    set_assignment_locale

    respond_to do |format|
      format.js
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("assignment_form_container",
                                                 partial: "assessment/assignments/form",
                                                 locals: { assignment: @assignment })
      end
    end
  end

  def create
    @assignment = Assignment.new(assignment_params)
    authorize! :create, @assignment
    @lecture = @assignment.lecture
    set_assignment_locale

    if @assignment.save
      @assignment.reload
      respond_to do |format|
        format.js
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("assignment_form_container", ""),
            turbo_stream.prepend("assessment-assessments-list",
                                 partial: "assessment/assessments/assessment_list_item",
                                 locals: { assessable: @assignment, lecture: @lecture })
          ]
        end
      end
    else
      respond_to do |format|
        format.js
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("assignment_form_container",
                                                   partial: "assessment/assignments/form",
                                                   locals: { assignment: @assignment }),
                 status: :unprocessable_content
        end
      end
    end
  end

  def update
    set_assignment_locale

    if @assignment.update(assignment_params)
      @assignment.update(medium: nil) if assignment_params[:medium_id].blank?
      @assignment.reload

      respond_to do |format|
        format.js
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("assignment_form_container", ""),
            turbo_stream.replace(ActionView::RecordIdentifier.dom_id(@assignment),
                                 partial: "assessment/assessments/assessment_list_item",
                                 locals: { assessable: @assignment, lecture: @lecture })
          ]
        end
      end
    else
      respond_to do |format|
        format.js
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("assignment_form_container",
                                                   partial: "assessment/assignments/form",
                                                   locals: { assignment: @assignment }),
                 status: :unprocessable_content
        end
      end
    end
  end

  def destroy
    set_assignment_locale

    if @assignment.destroy
      respond_to do |format|
        format.js
        format.turbo_stream do
          render turbo_stream: turbo_stream.remove(ActionView::RecordIdentifier.dom_id(@assignment))
        end
      end
    else
      respond_to do |format|
        format.js
        format.turbo_stream do
          head :unprocessable_content
        end
      end
    end
  end

  def cancel_edit
    respond_to do |format|
      format.js
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("assignment_form_container", "")
      end
    end
  end

  def cancel_new
    @lecture = Lecture.find_by(id: params[:lecture])
    assignment = Assignment.new(lecture: @lecture)
    authorize! :cancel_new, assignment
    set_assignment_locale
    @none_left = @lecture&.assignments&.none?

    respond_to do |format|
      format.js
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("assignment_form_container", "")
      end
    end
  end

  private

    def set_assignment
      @assignment = Assignment.find_by(id: params[:id])
      @lecture = @assignment&.lecture
      set_assignment_locale and return if @assignment

      redirect_to :root, alert: I18n.t("controllers.no_assignment")
    end

    def set_lecture
      @lecture = Lecture.find_by(id: assignment_params[:lecture_id])
      return if @lecture

      redirect_to :root, alert: I18n.t("controllers.no_lecture")
    end

    def set_assignment_locale
      I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
    end

    def assignment_params
      params.expect(assignment: [:title, :medium_id, :lecture_id,
                                 :deadline, :accepted_file_type,
                                 :deletion_date])
    end
end
