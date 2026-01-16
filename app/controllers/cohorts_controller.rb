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
    set_cohort_locale

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "modal-container",
          partial: "cohorts/modal",
          locals: { cohort: @cohort }
        )
      end
    end
  end

  def edit
    set_cohort_locale
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "modal-container",
          partial: "cohorts/modal",
          locals: { cohort: @cohort }
        )
      end
    end
  end

  def create
    cohort_attributes = cohort_params
    cohort_attributes = map_cohort_type_to_purpose(cohort_attributes)

    @cohort = Cohort.new(cohort_attributes)
    @cohort.context = @lecture
    authorize! :create, @cohort
    set_cohort_locale

    if @cohort.save
      flash.now[:notice] = t("controllers.cohorts.created")
    else
      @errors = @cohort.errors
    end

    respond_to do |format|
      format.turbo_stream do
        group_type = parse_group_type
        streams = create_turbo_streams(group_type)
        render turbo_stream: streams, status: @cohort.persisted? ? :ok : :unprocessable_content
      end
    end
  end

  def update
    set_cohort_locale
    if @cohort.update(cohort_params)
      flash.now[:notice] = t("controllers.cohorts.updated")
    else
      @errors = @cohort.errors
    end

    respond_to do |format|
      format.turbo_stream do
        group_type = parse_group_type
        streams = []

        if @cohort.errors.empty?
          streams << update_roster_groups_list_stream(group_type)
          streams << refresh_campaigns_index_stream(@cohort.lecture)
          streams << turbo_stream.update("modal-container", "")
        else
          streams << turbo_stream.replace(view_context.dom_id(@cohort, "form"),
                                          partial: "cohorts/modal_form",
                                          locals: { cohort: @cohort })
        end

        streams << stream_flash if flash.present?
        render turbo_stream: streams, status: @cohort.errors.empty? ? :ok : :unprocessable_content
      end
    end
  end

  def destroy
    set_cohort_locale
    if @cohort.destroy
      flash.now[:notice] = t("controllers.cohorts.destroyed")
    else
      flash.now[:alert] = t("controllers.cohorts.destruction_failed")
    end

    respond_to do |format|
      format.turbo_stream do
        group_type = parse_group_type
        render turbo_stream: [update_roster_groups_list_stream(group_type),
                              refresh_campaigns_index_stream(@cohort.lecture),
                              stream_flash]
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
      else
        redirect_to :root, alert: I18n.t("controllers.no_cohort")
      end
    end

    def set_cohort_locale
      I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
    end

    def cohort_params
      permitted = [:title, :capacity, :description]
      permitted += [:purpose, :propagate_to_lecture] unless @cohort&.persisted?
      params.expect(cohort: permitted)
    end

    def map_cohort_type_to_purpose(attributes)
      return attributes unless attributes[:purpose].present?

      purpose_mapping = {
        "enrollment" => { purpose: :enrollment, propagate_to_lecture: true },
        "planning" => { purpose: :planning, propagate_to_lecture: false },
        "general" => { purpose: :general }
      }

      config = purpose_mapping[attributes[:purpose]]
      return attributes unless config

      attributes[:purpose] = config[:purpose]
      if config.key?(:propagate_to_lecture)
        attributes[:propagate_to_lecture] =
          config[:propagate_to_lecture]
      end
      attributes
    end

    def create_turbo_streams(group_type)
      streams = []

      if @cohort.persisted?
        streams << update_roster_groups_list_stream(group_type)
        streams << refresh_campaigns_index_stream(@lecture)
        streams << turbo_stream.update("modal-container", "")
      else
        streams << turbo_stream.replace(view_context.dom_id(@cohort, "form"),
                                        partial: "cohorts/modal_form",
                                        locals: { cohort: @cohort })
      end

      streams << stream_flash if flash.present?
      streams
    end

    def update_roster_groups_list_stream(group_type)
      component = RosterOverviewComponent.new(lecture: @lecture,
                                              group_type: group_type)
      turbo_stream.update("roster_groups_list",
                          partial: "roster/components/groups_tab",
                          locals: {
                            groups: component.groups,
                            total_participants: component.total_participants,
                            group_type: group_type,
                            component: component
                          })
    end

    def parse_group_type
      if params[:group_type].is_a?(Array)
        params[:group_type].map(&:to_sym)
      else
        params[:group_type].presence&.to_sym || :cohorts
      end
    end
end
