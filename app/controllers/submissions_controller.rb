# SubmissionsController
class SubmissionsController < ApplicationController
  before_action :set_submission, only: [:edit, :destroy, :leave, :cancel_edit,
                                        :update, :refresh_token,
                                        :enter_invitees, :invite]
  before_action :set_assignment, only: [:new, :enter_code, :cancel_new]
  before_action :set_lecture, only: :index
  authorize_resource

  def index
    @assignments = @lecture.assignments
    @current_assignment = Assignment.current_in_lecture(@lecture)
    @previous_assignment = @current_assignment&.previous
    @old_assignments = @assignments.expired.order('deadline DESC') - [@previous_assignment]
    @future_assignments = @assignments.active.order(:deadline) - [@current_assignment]
  end

  def new
  	@submission = Submission.new
    @submission.assignment = @assignment
  	@lecture = @assignment.lecture
  end

  def edit
  end

  def update
    old_manuscript = @submission.manuscript_data
    @old_filename = @submission.manuscript_filename
    @submission.update(submission_params)
    if @submission.valid?
      if params[:submission][:detach_user_manuscript] == 'true'
        @submission.update(manuscript: nil)
        send_upload_removal_email(@submission.users)
      elsif @submission.manuscript != old_manuscript
        send_upload_email(@submission.users)
      end
    end
    render :create
  end

  def create
  	@submission = Submission.new(submission_params)
    @submission.users << current_user
    @submission.save
    @assignment = @submission.assignment
    return unless @submission.valid?
    send_invitation_emails
    return unless @submission.manuscript
    send_upload_email(User.where(id: current_user.id))
  end

  def destroy
    @submission.destroy
  end

  def enter_code
  end

  def redeem_code
    code = params[:code]
    @submission = Submission.find_by(token: code)
    check_code_and_join
    unless @error
      redirect_to submissions_path(params:
                                   { lecture_id: @submission.tutorial
                                                            .lecture_id }),
                  notice: t('submission.joined_successfully',
                            assignment: @submission.assignment.title)
      return
    end
    redirect_to :start, alert: t('submission.failed_redemption',
                                 message: @error)
  end

  def join
    @assignment = Assignment.find_by_id(join_params[:assignment_id])
    code = join_params[:code]
    @submission = Submission.find_by(token: code, assignment: @assignment)
    check_code_and_join
  end

  def leave
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
    @submission = Submission.find_by_id(params[:id])
    if @submission && @submission.manuscript
      send_file @submission.manuscript.to_io,
      					type: 'application/pdf',
      					disposition: 'inline'
    elsif @submission
      redirect_to :start, alert: t('submission.no_manuscript_yet')
    else
      redirect_to :start, alert: t('submission.exists_no_longer')
    end
  end

  def refresh_token
  	@submission.update(token: Submission.generate_token)
  end

  def enter_invitees
  end

  def invite
  	send_invitation_emails
  	render :create
  end

  private

  def set_submission
    @submission = Submission.find_by_id(params[:id])
    @assignment = @submission&.assignment
    @lecture = @assignment&.lecture
    return if @submission
    flash[:alert] = I18n.t('controllers.no_submission')
    render js: "window.location='#{root_path}'"
  end

  def submission_params
    params.require(:submission).permit(:tutorial_id, :assignment_id,
                                       :manuscript)
  end

  def set_assignment
    @assignment = Assignment.find_by_id(params[:assignment_id])
    return if @assignment
    flash[:alert] = I18n.t('controllers.no_assignment')
    render js: "window.location='#{root_path}'"
    return
  end

  def set_lecture
    @lecture = Lecture.find_by_id(params[:lecture_id])
    return if @lecture
    redirect_to :root, alert: I18n.t('controllers.no_lecture_given')
  end

  def join_params
    params.require(:join).permit(:code, :assignment_id)
  end

  def invitation_params
    params.require(:submission).permit(invitee_ids: [])
  end

  def send_invitation_emails
    invitees = User.where(id: invitation_params[:invitee_ids])
    invitees.each do |i|
      NotificationMailer.with(recipient: i,
                              locale: i.locale,
                              assignment: @assignment,
                              code: @submission.token,
                              issuer: current_user)
                        .submission_invitation_email.deliver_now
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
                        .submission_upload_email.deliver_now
    end
  end

  def send_upload_removal_email(users)
    users.email_for_submission_removal.each do |u|
      NotificationMailer.with(recipient: u,
                              locale: u.locale,
                              submission: @submission,
                              remover: current_user,
                              filename: @old_filename)
                        .submission_upload_removal_email.deliver_now
    end
  end

  def check_code_validity
    if !@submission && @assignment
      @error = I18n.t('submission.invalid_code_for_assignment',
                      assignment: @assignment.title)
    elsif !@submission
      @error = I18n.t('submission.invalid_code')
    elsif @assignment && !@assignment.active?
      @error = I18n.t('submission.assignment_expired')
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
                        .submission_join_email.deliver_now
    end
  end

  def send_leave_email
    (@submission.users.email_for_submission_leave - [current_user]).each do |u|
      NotificationMailer.with(recipient: u,
                              locale: u.locale,
                              submission: @submission,
                              user: current_user)
                        .submission_leave_email.deliver_now
    end
  end

  def remove_invitee_status
  	@submission.update(invited_user_ids: @submission.invited_user_ids -
  																				 [current_user.id])
  end
end