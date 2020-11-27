# TutorialsController
class TutorialsController < ApplicationController
  before_action :set_tutorial, only: [:edit, :destroy, :update, :cancel_edit,
                                      :bulk_download, :bulk_upload,
                                      :export_teams]
  before_action :set_assignment, only: [:bulk_download, :bulk_upload,
                                        :export_teams]
  before_action :set_lecture, only: [:index, :overview]
  before_action :set_lecture_from_form, only: [:create]
  before_action :check_tutor_status, only: :index
  before_action :check_editor_status, only: [:overview, :create]
  authorize_resource

  require 'rubygems'
  require 'zip'

  def index
    @assignments = @lecture.assignments.expired.order('deadline DESC')
    @assignment = Assignment.find_by_id(params[:assignment]) ||
                    @assignments&.first
    @tutorials = current_user.given_tutorials.where(lecture: @lecture)
    @tutorial = Tutorial.find_by_id(params[:tutorial]) || @tutorials.first
    @stack = @assignment&.submissions&.where(tutorial: @tutorial)&.proper
                        &.order(:last_modification_by_users_at)
  end

  def overview
    @assignments = @lecture.assignments.expired.order('deadline DESC')
    @assignment = Assignment.find_by_id(params[:assignment]) ||
                    @assignments&.first
  end

  def new
    @tutorial = Tutorial.new
    @lecture = Lecture.find_by_id(params[:lecture_id])
    set_tutorial_locale
    @tutorial.lecture = @lecture
  end

  def create
    @tutorial = Tutorial.new(tutorial_params)
    @lecture = @tutorial&.lecture
    set_tutorial_locale
    @tutorial.save
    @errors = @tutorial.errors
  end

  def edit
  end

  def update
    @tutorial.update(tutorial_params)
    @errors = @tutorial.errors
    return if @errors.present?
  end

  def destroy
    @tutorial.destroy
  end

  def cancel_edit
  end

  def cancel_new
    @lecture = Lecture.find_by_id(params[:lecture])
    set_tutorial_locale
    @none_left = @lecture&.tutorials&.none?
  end

  def bulk_download
    @zipped_submissions = Submission.zip_submissions!(@tutorial, @assignment)
    if @zipped_submissions.is_a?(StringIO)
    send_data @zipped_submissions.read,
              filename: @assignment.title + '@' + @tutorial.title + '.zip',
              type: 'application/zip',
              disposition: 'attachment'
    else
      flash[:alert] = I18n.t('controllers.tutorials.bulk_download_failed',
                             message: @zipped_submissions)
      redirect_to lecture_tutorials_path(@tutorial.lecture,
                                         params:
                                          { assignment: @assignment.id,
                                            tutorial: @tutorial.id })
    end
  end

  def bulk_upload
    files = JSON.parse(params[:package])
    @report =@tutorial.add_bulk_corrections!(@assignment, files)
    @stack = @assignment.submissions.where(tutorial: @tutorial).proper
                        .order(:last_modification_by_users_at)
    send_correction_upload_emails
  end

  def validate_certificate
    @lecture = Lecture.find_by_id(params[:lecture_id])
    set_tutorial_locale
  end

  def export_teams
    respond_to do |format|
      format.html { head :ok }
      format.csv { send_data @tutorial.teams_to_csv(@assignment),
                             filename: "#{@tutorial.title}-#{@assignment.title}.csv" }
    end
  end

  private

  def set_tutorial
    @tutorial = Tutorial.find_by_id(params[:id])
    @lecture = @tutorial&.lecture
    set_tutorial_locale and return if @tutorial
    redirect_to :root, alert: I18n.t('controllers.no_tutorial')
  end

  def set_assignment
    @assignment = Assignment.find_by_id(params[:ass_id])
    return if @assignment
    redirect_to :root, alert: I18n.t('controllers.no_assignment')
  end

  def set_lecture
    @lecture = Lecture.find_by_id(params[:id])
    set_tutorial_locale and return if @lecture
    redirect_to :root, alert: I18n.t('controllers.no_lecture')
  end

  def set_lecture_from_form
    @lecture = Lecture.find_by_id(tutorial_params[:lecture_id])
    return if @lecture
    redirect_to :root, alert: I18n.t('controllers.no_lecture')
  end

  def set_tutorial_locale
    I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
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
    params.require(:tutorial).permit(:title, :lecture_id, tutor_ids: [])
  end

  def bulk_params
    params.permit(:package)
  end

  def send_correction_upload_emails
    @report[:successful_saves].each do |submission|
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