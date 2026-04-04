class CohortsController < ApplicationController
  include ::RegistrationCampaignContext

  helper RosterHelper

  before_action :set_lecture, only: [:new, :create]
  before_action :set_cohort, only: [:edit, :update, :destroy]
  authorize_resource except: [:new, :create]

  def current_ability
    @current_ability ||= CohortAbility.new(current_user)
  end

  def new
    @cohort = Cohort.new(context: @lecture)
    @cohort.assign_attributes(cohort_params) if params[:cohort].present?
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
    @cohort = Cohort.new(cohort_params)
    @cohort.skip_campaigns = true if registration_section_no_campaign?
    @cohort.context = @lecture
    authorize! :create, @cohort
    set_cohort_locale

    persisted = false
    Cohort.transaction do
      persisted = @cohort.save
      raise(ActiveRecord::Rollback) unless persisted

      persisted = apply_registration_context(registerable: @cohort,
                                             lecture: @lecture,
                                             error_target: @cohort)
      raise(ActiveRecord::Rollback) unless persisted
    end

    flash.now[:notice] = t("controllers.cohorts.created") if persisted
    @errors = @cohort.errors

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
        parse_group_type
        streams = []

        if @cohort.errors.empty?
          streams << stream_flash if flash.present?
          streams << refresh_campaigns_index_stream(@cohort.lecture)
          streams << turbo_stream.update("modal-container", "")
        else
          streams << turbo_stream.replace(view_context.dom_id(@cohort, "form"),
                                          partial: "cohorts/modal_form",
                                          locals: { cohort: @cohort })
        end

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
        parse_group_type
        streams = []
        streams << stream_flash if flash.present?
        streams << refresh_campaigns_index_stream(@cohort.lecture)
        render turbo_stream: streams
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
      permitted << :propagate_to_lecture unless @cohort&.persisted?
      params.expect(cohort: permitted)
    end

    def create_turbo_streams(_group_type)
      streams = []

      if @cohort.persisted?
        streams << stream_flash if flash.present?
        streams << refresh_campaigns_index_stream(@lecture)
      else
        streams << turbo_stream.replace(view_context.dom_id(@cohort, "form"),
                                        partial: "cohorts/modal_form",
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

    def registration_section_no_campaign?
      params[:registration_section].to_s == "no_campaign"
    end
end
