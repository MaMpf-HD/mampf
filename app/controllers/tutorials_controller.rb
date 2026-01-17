# TutorialsController
class TutorialsController < ApplicationController
  helper RosterHelper

  before_action :set_tutorial, only: [:edit, :destroy, :update, :cancel_edit,
                                      :bulk_download_submissions,
                                      :bulk_download_corrections,
                                      :bulk_upload,
                                      :export_teams]
  before_action :set_assignment, only: [:bulk_download_submissions,
                                        :bulk_download_corrections,
                                        :bulk_upload,
                                        :export_teams]
  before_action :set_lecture, only: [:index, :overview]
  before_action :set_lecture_from_form, only: [:create]
  before_action :can_view_index, only: :index
  authorize_resource except: [:index, :overview, :create, :validate_certificate,
                              :new, :cancel_new]

  require "rubygems"
  require "zip"

  def current_ability
    @current_ability ||= TutorialAbility.new(current_user)
  end

  def index
    authorize! :index, Tutorial.new, @lecture
    @assignments = @lecture.assignments.order(deadline: :desc)
    @assignment = Assignment.find_by(id: params[:assignment]) ||
                  @assignments&.first
    @tutorials = if current_user.editor_or_teacher_in?(@lecture)
      @lecture.tutorials
    else
      current_user.given_tutorials.where(lecture: @lecture)
    end
    @tutorial = Tutorial.find_by(id: params[:tutorial]) || current_user.tutorials(@lecture).first
    @stack = @assignment&.submissions&.where(tutorial: @tutorial)&.proper
                        &.order(:last_modification_by_users_at)

    render layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def overview
    authorize! :overview, Tutorial.new, @lecture
    @assignments = @lecture.assignments.order(deadline: :desc)
    @assignment = Assignment.find_by(id: params[:assignment]) ||
                  @assignments&.first
    @tutorials = @lecture.tutorials

    render layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def new
    @tutorial = Tutorial.new
    @lecture = Lecture.find_by(id: params[:lecture_id])
    set_tutorial_locale
    @tutorial.lecture = @lecture
    authorize! :new, @tutorial

    respond_to do |format|
      format.js do
        Rails.logger.warn("[MUESLI-DEPRECATION] Legacy JS format accessed in " \
                          "TutorialsController#new")
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "modal-container",
          partial: "tutorials/modal",
          locals: { tutorial: @tutorial }
        )
      end
    end
  end

  def edit
    authorize! :edit, @tutorial

    respond_to do |format|
      format.js do
        Rails.logger.warn("[MUESLI-DEPRECATION] Legacy JS format accessed in " \
                          "TutorialsController#edit")
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "modal-container",
          partial: "tutorials/modal",
          locals: { tutorial: @tutorial }
        )
      end
    end
  end

  def create
    @tutorial = Tutorial.new(tutorial_params)
    authorize! :create, @tutorial
    @lecture = @tutorial.lecture
    set_tutorial_locale
    flash.now[:notice] = t("controllers.tutorials.created") if @tutorial.save
    @errors = @tutorial.errors

    respond_to do |format|
      format.js do
        Rails.logger.warn("[MUESLI-DEPRECATION] Legacy JS format accessed in " \
                          "TutorialsController#create")
      end
      format.turbo_stream do
        group_type = parse_group_type

        streams = create_turbo_streams(group_type)
        render turbo_stream: streams, status: @tutorial.persisted? ? :ok : :unprocessable_content
      end
    end
  end

  def update
    authorize! :update, @tutorial

    if @tutorial.update(tutorial_params)
      flash.now[:notice] = t("controllers.tutorials.updated")
    else
      @errors = @tutorial.errors
    end

    respond_to do |format|
      format.js do
        Rails.logger.warn("[MUESLI-DEPRECATION] Legacy JS format accessed in " \
                          "TutorialsController#update")
      end
      format.turbo_stream do
        group_type = parse_group_type
        streams = []

        if @tutorial.errors.empty?
          streams << update_roster_groups_list_stream(group_type)
          streams << refresh_campaigns_index_stream(@tutorial.lecture)
        else
          streams << turbo_stream.replace(view_context.dom_id(@tutorial, "form"),
                                          partial: "tutorials/modal_form",
                                          locals: { tutorial: @tutorial })
        end

        streams << stream_flash if flash.present?
        render turbo_stream: streams, status: @tutorial.errors.empty? ? :ok : :unprocessable_content
      end
    end
  end

  def destroy
    if @tutorial.destroy
      flash.now[:notice] = t("controllers.tutorials.destroyed")
    else
      flash.now[:alert] = t("controllers.tutorials.destruction_failed")
    end

    respond_to do |format|
      format.js do
        Rails.logger.warn("[MUESLI-DEPRECATION] Legacy JS format accessed in " \
                          "TutorialsController#destroy")
      end
      format.turbo_stream do
        group_type = parse_group_type
        render turbo_stream: [update_roster_groups_list_stream(group_type),
                              refresh_campaigns_index_stream(@tutorial.lecture),
                              stream_flash]
      end
    end
  end

  def cancel_edit
  end

  def cancel_new
    @lecture = Lecture.find_by(id: params[:lecture])
    authorize! :cancel_new, Tutorial.new(lecture: @lecture)
    set_tutorial_locale
    @none_left = @lecture&.tutorials&.none?
  end

  def bulk_download_submissions
    @zipped_submissions = Submission.zip_submissions!(@tutorial, @assignment)
    bulk_download(@zipped_submissions)
  end

  def bulk_download_corrections
    @zipped_corrections = Submission.zip_corrections!(@tutorial, @assignment)
    bulk_download(@zipped_corrections, "-Corrections")
  end

  def bulk_upload
    files = JSON.parse(params[:files])
    @report = Submission.bulk_corrections!(@tutorial, @assignment, files)
    @stack = @assignment.submissions.where(tutorial: @tutorial).proper
                        .order(:last_modification_by_users_at)
    send_correction_upload_emails
  # in case an empty string for files is sent
  rescue JSON::ParserError
    flash[:alert] = I18n.t("tutorial.bulk_upload.error")
  end

  def validate_certificate
    authorize! :validate_certificate, Tutorial.new
    @lecture = Lecture.find_by(id: params[:lecture_id])
    set_tutorial_locale
  end

  def export_teams
    respond_to do |format|
      format.html { head :ok }
      format.csv do
        send_data(@tutorial.teams_to_csv(@assignment),
                  filename: "#{@tutorial.title}-#{@assignment.title}.csv")
      end
    end
  end

  private

    def set_tutorial
      @tutorial = Tutorial.find_by(id: params[:id])
      @lecture = @tutorial&.lecture
      set_tutorial_locale and return if @tutorial

      redirect_to :root, alert: I18n.t("controllers.no_tutorial")
    end

    def set_assignment
      @assignment = Assignment.find_by(id: params[:ass_id])
      return if @assignment

      redirect_to :root, alert: I18n.t("controllers.no_assignment")
    end

    def set_lecture
      @lecture = Lecture.find_by(id: params[:id])
      set_tutorial_locale and return if @lecture

      redirect_to :root, alert: I18n.t("controllers.no_lecture")
    end

    def set_lecture_from_form
      @lecture = Lecture.find_by(id: tutorial_params[:lecture_id])
      return if @lecture

      redirect_to :root, alert: I18n.t("controllers.no_lecture")
    end

    def set_tutorial_locale
      I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
    end

    def can_view_index
      return if current_user.in?(@lecture.tutors) || current_user.editor_or_teacher_in?(@lecture)

      redirect_to :root, alert: I18n.t("controllers.no_tutor_in_this_lecture")
    end

    def tutorial_params
      params.expect(tutorial: [:title, :lecture_id, :capacity, { tutor_ids: [] }])
    end

    def bulk_params
      params.permit(:package)
    end

    def bulk_download(zipped, end_of_file = "")
      if zipped.is_a?(StringIO)
        send_data(zipped.read,
                  filename: "#{@assignment.title}@#{@tutorial.title}#{end_of_file}.zip",
                  type: "application/zip",
                  disposition: "attachment")
      else
        flash[:alert] = I18n.t("controllers.tutorials.bulk_download_failed",
                               message: zipped)
        redirect_to lecture_tutorials_path(@tutorial.lecture,
                                           params:
                                            { assignment: @assignment.id,
                                              tutorial: @tutorial.id })
      end
    end

    def send_correction_upload_emails
      @report[:successful_saves]&.each do |submission|
        submission.users.email_for_correction_upload.each do |u|
          NotificationMailer.with(recipient: u,
                                  locale: u.locale,
                                  submission: submission,
                                  tutor: current_user)
                            .correction_upload_email.deliver_later
        end
      end
    end

    def parse_group_type
      if params[:group_type].is_a?(Array)
        params[:group_type].map(&:to_sym)
      else
        params[:group_type].presence&.to_sym || :tutorials
      end
    end

    def create_turbo_streams(group_type)
      streams = []

      if @tutorial.persisted?
        streams << update_roster_groups_list_stream(group_type)
        streams << refresh_campaigns_index_stream(@lecture)
        streams << turbo_stream.update("modal-container", "")
      else
        streams << turbo_stream.replace(view_context.dom_id(@tutorial, "form"),
                                        partial: "tutorials/modal_form",
                                        locals: { tutorial: @tutorial })
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
                            group_type: group_type,
                            component: component
                          })
    end
end
