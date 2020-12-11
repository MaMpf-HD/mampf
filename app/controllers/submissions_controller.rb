# SubmissionsController
class SubmissionsController < ApplicationController
  before_action :set_submission, except: [:index, :new, :create, :enter_code,
                                          :redeem_code, :join, :cancel_new]
  before_action :set_assignment, only: [:new, :enter_code, :cancel_new]
  before_action :set_lecture, only: :index
  before_action :set_too_late, only: [:edit, :update, :invite, :destroy, :leave]
  before_action :prevent_caching, only: :show_manuscript
  before_action :check_if_tutorials, only: :index
  before_action :check_if_assignments, only: :index
  before_action :check_student_status, only: :index
  before_action :set_disposition, only: [:show_manuscript, :show_correction]

  def index
    @assignments = @lecture.assignments
    @current_assignments = @lecture.current_assignments
    @previous_assignments = @lecture.previous_assignments
    @old_assignments = @assignments.expired.order('deadline DESC') -
                         @previous_assignments
    @future_assignments = @assignments.active.order(:deadline) -
                            @current_assignments
  end

  def new
  	@submission = Submission.new
    @submission.assignment = @assignment
    set_submission_locale
  end

  def edit
  end

  def update
  	return if @too_late
    old_manuscript_data = @submission.manuscript_data
    @old_filename = @submission.manuscript_filename
    if submission_manuscript_params[:manuscript].present?
      @submission.manuscript = submission_manuscript_params[:manuscript]
      @errors = @submission.check_file_properties(@submission.manuscript
                                                             .metadata,
                                                  :manuscript)
      return if @errors.present?
      @submission.save
      @errors = @submission.errors
      return unless @submission.valid?
    end
    @submission.update(submission_update_params)
    if @submission.valid?
      if params[:submission][:detach_user_manuscript] == 'true'
        @submission.update(manuscript: nil,
                           last_modification_by_users_at: Time.now)
        send_upload_removal_email(@submission.users)
      elsif @submission.manuscript_data != old_manuscript_data
        @submission.update(last_modification_by_users_at: Time.now)
        send_upload_email(@submission.users)
      end
    end
    @errors = @submission.errors
  end

  def create
  	@submission = Submission.new(submission_create_params)
    @lecture = @submission&.assignment&.lecture
    set_submission_locale
    @too_late = @submission.not_updatable?
  	return if @too_late
    if submission_manuscript_params[:manuscript].present?
      @submission.manuscript = submission_manuscript_params[:manuscript]
      @errors = @submission.check_file_properties(@submission.manuscript
                                                             .metadata,
                                                  :manuscript)
      return if @errors.present?
    end
    @submission.user_submission_joins.build(user: current_user)
    @submission.save
    @assignment = @submission.assignment
    @errors = @submission.errors
    return unless @submission.valid?
    send_invitation_emails
    @submission.update(last_modification_by_users_at: Time.now)
    return unless @submission.manuscript
    send_upload_email(User.where(id: current_user.id))
  end

  def destroy
    return if @too_late
    @submission.destroy
  end

  def enter_code
  end

  def redeem_code
    code = params[:code]
    @submission = Submission.find_by(token: code)
    @assignment = @submission&.assignment
    check_code_and_join
    unless @error
      redirect_to lecture_submissions_path(@submission.tutorial.lecture),
                  notice: t('submission.joined_successfully',
                            assignment: @submission.assignment.title)
      return
    end
    redirect_to :start, alert: t('submission.failed_redemption',
                                 message: @error)
  end

  def join
    @assignment = Assignment.find_by_id(join_params[:assignment_id])
    @lecture = @assignment.lecture
    set_submission_locale
    code = join_params[:code]
    @submission = Submission.find_by(token: code, assignment: @assignment)
    check_code_and_join
  end

  def leave
    return if @too_late
    if @submission.users.count == 1
      @error = I18n.t('submission.no_partners_no_leave')
      return
    end
    @submission.users.delete(current_user)
    send_leave_email
  end

  def cancel_edit
  end

  def cancel_new
  end

  def show_manuscript
    if @submission && @submission.manuscript
      send_file @submission.manuscript.to_io,
      					type: @submission.manuscript_mime_type,
      					disposition: @disposition,
                filename: @submission.manuscript_filename
    elsif @submission
      redirect_to :start, alert: t('submission.no_manuscript_yet')
    else
      redirect_to :start, alert: t('submission.exists_no_longer')
    end
  end

  def show_correction
    if @submission && @submission.correction
      send_file @submission.correction.to_io,
                type: @submission.correction_mime_type,
                disposition: @disposition,
                filename: @submission.correction_filename
    elsif @submission
      redirect_to :start, alert: t('submission.no_correction_yet')
    else
      redirect_to :start, alert: t('submission.exists_no_longer')
    end
  end

  def refresh_token
  	@submission.update(token: Submission.generate_token)
  end

  def enter_invitees
  	@too_late = @submission.assignment.totally_expired?
  end

  def invite
  	if @too_late
  		render :create
  		return
  	end
  	send_invitation_emails
  	render :create
  end

  def edit_correction
  end

  def cancel_edit_correction
  end

  def add_correction
  	if correction_params[:correction].present?
      @submission.correction = correction_params[:correction]
      @errors = @submission.check_file_properties(@submission.correction
                                                             .metadata,
                                                  :correction)
      return if @errors.present?
      @submission.save
      @errors = @submission.errors
      return unless @submission.valid?
    end
    @submission.update(correction_params)
    @errors = @submission.errors
    return if @errors.present?
    send_correction_upload_email(@submission.users)
  end

  def delete_correction
    @submission.update(correction: nil)
    render :add_correction
  end

  def select_tutorial
    @tutorial = @submission.tutorial
    @lecture = @submission.assignment.lecture
  end

  def cancel_action
  end

  def move
    @old_tutorial = @submission.tutorial
    @submission.update(move_params)
    @tutorial = @submission.tutorial
  end

  def accept
    @submission.update(accepted: true)
    send_acceptance_email(@submission.users)
  end

  def reject
    @submission.update(accepted: false)
    send_rejection_email(@submission.users)
  end

  private

  def set_submission
    @submission = Submission.find_by_id(params[:id])
    @assignment = @submission&.assignment
    @lecture = @assignment&.lecture
    set_submission_locale
    return if @submission
    flash[:alert] = I18n.t('controllers.no_submission')
    render js: "window.location='#{root_path}'"
  end

  def submission_create_params
    params.require(:submission).permit(:tutorial_id, :assignment_id)
  end

  # disallow modification of assignment
  def submission_update_params
    params.require(:submission).permit(:tutorial_id)
  end

  # disallow modification of assignment
  def submission_manuscript_params
    params.require(:submission).permit(:manuscript)
  end

  def set_assignment
    @assignment = Assignment.find_by_id(params[:assignment_id])
    @lecture = @assignment&.lecture
    set_submission_locale
    return if @assignment
    flash[:alert] = I18n.t('controllers.no_assignment')
    render js: "window.location='#{root_path}'"
    return
  end

  def set_lecture
    @lecture = Lecture.find_by_id(params[:id])
    set_submission_locale and return if @lecture
    redirect_to :root, alert: I18n.t('controllers.no_lecture')
  end

  def set_too_late
    @too_late = @submission.not_updatable?
  end

  def set_submission_locale
    I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
  end

  def join_params
    params.require(:join).permit(:code, :assignment_id)
  end

  def invitation_params
    params.require(:submission).permit(invitee_ids: [])
  end

  def correction_params
    params.require(:submission).permit(:correction)
  end

  def move_params
    params.require(:submission).permit(:tutorial_id)
  end

  def send_invitation_emails
    invitees = User.where(id: invitation_params[:invitee_ids])
    invitees.each do |i|
      NotificationMailer.with(recipient: i,
                              locale: i.locale,
                              assignment: @assignment,
                              code: @submission.token,
                              issuer: current_user)
                        .submission_invitation_email.deliver_later
    end
    @submission.update(invited_user_ids: @submission.invited_user_ids |
    																			 invitees.pluck(:id))
  end

  def send_upload_email(users)
    users.email_for_submission_upload.each do |u|
      NotificationMailer.with(recipient: u,
                              locale: u.locale,
                              submission: @submission,
                              uploader: current_user,
                              filename: @submission.manuscript_filename)
                        .submission_upload_email.deliver_later
    end
  end

  def send_upload_removal_email(users)
    users.email_for_submission_removal.each do |u|
      NotificationMailer.with(recipient: u,
                              locale: u.locale,
                              submission: @submission,
                              remover: current_user,
                              filename: @old_filename)
                        .submission_upload_removal_email.deliver_later
    end
  end

  def send_correction_upload_email(users)
    users.email_for_correction_upload.each do |u|
      NotificationMailer.with(recipient: u,
                              locale: u.locale,
                              submission: @submission,
                              tutor: current_user)
                        .correction_upload_email.deliver_later
    end
  end

  def send_acceptance_email(users)
    users.email_for_submission_decision.each do |u|
      NotificationMailer.with(recipient: u,
                              locale: u.locale,
                              submission: @submission)
                        .submission_acceptance_email.deliver_later
    end
  end

  def send_rejection_email(users)
    users.email_for_submission_decision.each do |u|
      NotificationMailer.with(recipient: u,
                              locale: u.locale,
                              submission: @submission)
                        .submission_rejection_email.deliver_later
    end
  end

  def check_code_validity
    if !@submission && @assignment
      @error = I18n.t('submission.invalid_code_for_assignment',
                      assignment: @assignment.title)
    elsif !@submission
      @error = I18n.t('submission.invalid_code')
    elsif @assignment&.totally_expired?
      @error = I18n.t('submission.assignment_expired')
    elsif @submission.correction
      @error = I18n.t('submission.already_corrected')
    elsif current_user.in?(@submission.users)
      @error = I18n.t('submission.already_in')
    elsif !@submission.tutorial.lecture.in?(current_user.lectures)
      @error = I18n.t('submission.lecture_not_subscribed')
    end
  end

  def check_code_and_join
  	check_code_validity
  	unless @error
    	@join = UserSubmissionJoin.new(user: current_user,
    														 		 submission: @submission)
    	@join.save
    	if @join.valid?
        @submission.update(last_modification_by_users_at: Time.now)
        send_join_email
        remove_invitee_status
      else
    		@error = @join.errors[:base].join(', ')
    	end
    end
  end

  def send_join_email
    (@submission.users.email_for_submission_join - [current_user]).each do |u|
      NotificationMailer.with(recipient: u,
                              locale: u.locale,
                              submission: @submission,
                              user: current_user)
                        .submission_join_email.deliver_later
    end
  end

  def send_leave_email
    (@submission.users.email_for_submission_leave - [current_user]).each do |u|
      NotificationMailer.with(recipient: u,
                              locale: u.locale,
                              submission: @submission,
                              user: current_user)
                        .submission_leave_email.deliver_later
    end
  end

  def remove_invitee_status
  	@submission.update(invited_user_ids: @submission.invited_user_ids -
  																				 [current_user.id])
  end

  def check_student_status
    return if current_user.proper_student_in?(@lecture)
    redirect_to :root, alert: I18n.t('controllers.no_student_status_in_lecture')
  end

  def check_if_tutorials
    return if @lecture.tutorials.any?
    redirect_to :root, alert: I18n.t('controllers.no_tutorials_in_lecture')
  end

  def check_if_assignments
    return if @lecture.assignments.any?
    redirect_to :root, alert: I18n.t('controllers.no_assignments_in_lecture')
  end

  def set_disposition
    @disposition = params[:download] == 'true' ? 'attachment' : 'inline'
    accepted = @submission.assignment.accepted_file_type
    return unless accepted.in?(Assignment.non_inline_file_types)
    @disposition = 'attachment'
  end
end