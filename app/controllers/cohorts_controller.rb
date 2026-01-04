class CohortsController < ApplicationController
  helper RosterHelper

  before_action :set_lecture, only: [:new, :create]
  before_action :set_cohort, only: [:edit, :update, :destroy]
  authorize_resource except: [:new, :create]

  def current_ability
    @current_ability ||= CohortAbility.new(current_user)
  end

  def new
    @cohort = Cohort.new(context: @lecture)
    authorize! :new, @cohort

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "modal-container",
          partial: "cohorts/new_modal",
          locals: { cohort: @cohort }
        )
      end
    end
  end

  def edit
  end

  def create
    @cohort = Cohort.new(cohort_params)
    @cohort.context = @lecture
    authorize! :create, @cohort

    if @cohort.save
      flash.now[:notice] = t("controllers.cohorts.created")
    else
      @errors = @cohort.errors
    end

    respond_to do |format|
      format.turbo_stream do
        group_type = parse_group_type
        status = @cohort.errors.present? ? :unprocessable_content : :ok
        render turbo_stream: update_roster_groups_list_stream(group_type) + [stream_flash],
               status: status
      end
    end
  end

  def update
    if @cohort.update(cohort_params)
      flash.now[:notice] = t("controllers.cohorts.updated")
    else
      @errors = @cohort.errors
    end

    respond_to do |format|
      format.turbo_stream do
        group_type = parse_group_type
        streams = update_roster_groups_list_stream(group_type) + [stream_flash]
        render turbo_stream: streams.compact
      end
    end
  end

  def destroy
    if @cohort.destroy
      flash.now[:notice] = t("controllers.cohorts.destroyed")
    else
      flash.now[:alert] = t("controllers.cohorts.destruction_failed")
    end

    respond_to do |format|
      format.turbo_stream do
        group_type = parse_group_type
        streams = update_roster_groups_list_stream(group_type) + [stream_flash]
        render turbo_stream: streams.compact
      end
    end
  end

  private

    def set_lecture
      lecture_id = params[:lecture_id] || params.dig(:cohort, :lecture_id)
      @lecture = Lecture.find_by(id: lecture_id)
      if @lecture
        set_cohort_locale
      else
        redirect_to :root, alert: I18n.t("controllers.no_lecture")
      end
    end

    def set_cohort
      @cohort = Cohort.find_by(id: params[:id])
      if @cohort
        @lecture = @cohort.lecture
        set_cohort_locale
      else
        redirect_to :root, alert: I18n.t("controllers.no_cohort")
      end
    end

    def set_cohort_locale
      I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
    end

    def cohort_params
      params.expect(cohort: [:title, :capacity])
    end

    def update_roster_groups_list_stream(group_type)
      component = RosterOverviewComponent.new(lecture: @lecture,
                                              group_type: group_type)

      streams = []

      if @cohort.destroyed? || (@cohort.persisted? && @cohort.errors.empty?)
        # Success case: Update list and close modal
        streams << turbo_stream.update("roster_groups_list",
                                       partial: "roster/components/groups_tab",
                                       locals: {
                                         groups: component.groups,
                                         total_participants: component.total_participants,
                                         group_type: group_type,
                                         component: component
                                       })
        streams << turbo_stream.update("modal-container", "")
      elsif @cohort.new_record? || @cohort.errors.present?
        # Failure case or New form: Replace form
        # We need to check if the form exists in the DOM, otherwise this might fail silently or cause issues
        # But for now, let's assume the modal is open if we are editing/creating
        streams << turbo_stream.replace("new_cohort_form",
                                        partial: "cohorts/new_form",
                                        locals: { cohort: @cohort })
      end

      streams
    end

    def parse_group_type
      if params[:group_type].is_a?(Array)
        params[:group_type].map(&:to_sym)
      else
        params[:group_type].presence&.to_sym || :cohorts
      end
    end
end
