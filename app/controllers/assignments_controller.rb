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
        render turbo_stream: turbo_stream.update("assessments_container",
                                                 partial: "assessment/assessments/card_body_form",
                                                 locals: { assignment: @assignment,
                                                           lecture: @lecture })
      end
    end
  end

  def edit
    set_assignment_locale
  end

  def create
    @assignment = Assignment.new(assignment_params)
    authorize! :create, @assignment
    @lecture = @assignment.lecture
    set_assignment_locale

    if @assignment.save
      @assignment.reload
      assessment = @assignment.assessment
      tasks = assessment&.tasks&.order(:position) || []
      respond_to do |format|
        format.js
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("assessments_container",
                                AssessmentDashboardComponent.new(
                                  assessable: @assignment,
                                  assessment: assessment,
                                  lecture: @lecture,
                                  active_tab: "tasks",
                                  tasks: tasks
                                ))
          ]
        end
      end
    else
      respond_to do |format|
        format.js
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("assessments_container",
                                                   partial: "assessment/assessments/card_body_form",
                                                   locals: { assignment: @assignment,
                                                             lecture: @lecture }),
                 status: :unprocessable_content
        end
      end
    end
  end

  def update
    set_assignment_locale

    return unless @assignment.update(assignment_params)

    @assignment.update(medium: nil) if assignment_params[:medium_id].blank?
    @assignment.reload
  end

  def destroy
    set_assignment_locale
    @lecture = @assignment.lecture
    remaining_assignments = @lecture.assignments.where.not(id: @assignment.id)
                                    .includes(:assessment)
                                    .select(&:assessment)

    if @assignment.destroy
      respond_to do |format|
        format.js
        format.turbo_stream do
          if remaining_assignments.empty?
            render turbo_stream:
            turbo_stream.update("assessments_container",
                                partial: "assessment/assessments/empty_assignments")
          else
            render turbo_stream:
            turbo_stream.update("assessments_container",
                                partial: "assessment/assessments/index",
                                locals: { lecture: @lecture,
                                          assignments_with_assessments: remaining_assignments })
          end
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
  end

  def cancel_new
    @lecture = Lecture.find_by(id: params[:lecture])
    assignment = Assignment.new(lecture: @lecture)
    authorize! :cancel_new, assignment
    set_assignment_locale
    @none_left = @lecture&.assignments&.none?
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
                                 :requires_submission])
    end
end
