# TutorialsController
class TutorialsController < ApplicationController
  before_action :set_tutorial, only: [:edit, :destroy, :update, :cancel_edit,
                                      :bulk_download_submissions,
                                      :bulk_download_corrections,
                                      :bulk_upload,
                                      :export_teams]
  before_action :set_assignment, only: [:bulk_download_submissions,
                                        :bulk_download_corrections´,
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
    @assignments = @lecture.assignments.order("deadline DESC")
    @assignment = Assignment.find_by_id(params[:assignment]) ||
                  @assignments&.first
    @tutorials = if current_user.editor_or_teacher_in?(@lecture)
      @lecture.tutorials
    else
      current_user.given_tutorials.where(lecture: @lecture)
    end
    @tutorial = Tutorial.find_by_id(params[:tutorial]) || current_user.tutorials(@lecture).first
    @stack = @assignment&.submissions&.where(tutorial: @tutorial)&.proper
                        &.order(:last_modification_by_users_at)
  end

  def overview
    authorize! :overview, Tutorial.new, @lecture
    @assignments = @lecture.assignments.order("deadline DESC")
    @assignment = Assignment.find_by_id(params[:assignment]) ||
                  @assignments&.first
    @tutorials = @lecture.tutorials
  end

  def new
    @tutorial = Tutorial.new
    @lecture = Lecture.find_by_id(params[:lecture_id])
    set_tutorial_locale
    @tutorial.lecture = @lecture
    authorize! :new, @tutorial
  end

  def edit
  end

  def create
    @tutorial = Tutorial.new(tutorial_params)
    authorize! :create, @tutorial
    @lecture = @tutorial.lecture
    set_tutorial_locale
    @tutorial.save
    @errors = @tutorial.errors
  end

  def update
    @tutorial.update(tutorial_params)
    @errors = @tutorial.errors
    nil if @errors.present?
  end

  def destroy
    @tutorial.destroy
  end

  def cancel_edit
  end

  def cancel_new
    @lecture = Lecture.find_by_id(params[:lecture])
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
    @lecture = Lecture.find_by_id(params[:lecture_id])
    set_tutorial_locale
  end

  def export_teams
    respond_to do |format|
      format.html { head :ok }
      format.csv do
        send_data @tutorial.teams_to_csv(@assignment),
                  filename: "#{@tutorial.title}-#{@assignment.title}.csv"
      end
    end
  end

  private

    def set_tutorial
      @tutorial = Tutorial.find_by_id(params[:id])
      @lecture = @tutorial&.lecture
      set_tutorial_locale and return if @tutorial

      redirect_to :root, alert: I18n.t("controllers.no_tutorial")
    end

    def set_assignment
      @assignment = Assignment.find_by_id(params[:ass_id])
      return if @assignment

      redirect_to :root, alert: I18n.t("controllers.no_assignment")
    end

    def set_lecture
      @lecture = Lecture.find_by_id(params[:id])
      set_tutorial_locale and return if @lecture

      redirect_to :root, alert: I18n.t("controllers.no_lecture")
    end

    def set_lecture_from_form
      @lecture = Lecture.find_by_id(tutorial_params[:lecture_id])
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
      params.require(:tutorial).permit(:title, :lecture_id, tutor_ids: [])
    end

    def bulk_params
      params.permit(:package)
    end

    def bulk_download(zipped, end_of_file = "")
      if zipped.is_a?(StringIO)
        send_data zipped.read,
                  filename: @assignment.title + "@" + @tutorial.title + end_of_file + ".zip",
                  type: "application/zip",
                  disposition: "attachment"
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
end
