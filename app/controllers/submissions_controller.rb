# SubmissionsController
class SubmissionsController < ApplicationController
  before_action :set_submission, only: [:edit, :destroy, :leave, :cancel_edit,
                                        :update, :show_manuscript]
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
    @assignment = @submission.assignment
    @lecture = @assignment.lecture
  end

  def update
    @submission.update(submission_params)
    @assignment = @submission.assignment
    if @submission.valid? &&
         params[:submission][:detach_user_manuscript] == 'true'
      @submission.update(manuscript: nil)
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
  end

  def destroy
    @assignment = @submission.assignment
    @submission.destroy
  end

  def enter_code
  end

  def redeem_code
    code = params[:code]
    @submission = Submission.find_by(token: code)
    check_code_validity
    unless @error
      @submission.users << current_user
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
    check_code_validity
    return if @error
    @submission.users << current_user
  end

  def leave
    @assignment = @submission.assignment
    if @submission.users.count == 1
      @error = I18n.t('submission.no_partners_no_leave')
      return
    end
    @submission.users.delete(current_user)
  end

  def cancel_edit
    @assignment = @submission.assignment
    @lecture = @assignment.lecture
  end

  def cancel_new
  end

  def show_manuscript
    send_file @submission.manuscript.to_io,
    					type: 'application/pdf',
    					disposition: 'inline'
  end

  private

  def set_submission
    @submission = Submission.find_by_id(params[:id])
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
end