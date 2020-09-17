# SubmissionsController
class SubmissionsController < ApplicationController
  before_action :set_submission, only: [:edit, :destroy, :leave, :cancel_edit,
                                        :update, :show_manuscript]
  before_action :set_assignment, only: [:new, :enter_code, :cancel_new]

  def index
    @lecture = Lecture.find_by_id(params[:lecture_id])
    @assignments = @lecture.assignments.order(:deadline)
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

  def join
    @assignment = Assignment.find_by_id(join_params[:assignment_id])
    code = join_params[:code]
    @submission = Submission.find_by(token: code, assignment: @assignment)
    if !@submission
      @error = I18n.t('submission.invalid_code',
                      assignment: @assignment.title)
      return
    end
    if current_user.in?(@submission.users)
      @error = I18n.t('submission.already_in')
      return
    end
    if !@assignment.active?
      @error = I18n.t('submission.assignment_expired')
      return
    end
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
    file = Tempfile.new
    @submission.manuscript.stream(file.path)
    send_file file, type: 'application/pdf', disposition: 'inline'
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
                              code: @submission.token)
                        .submission_invitation_email.deliver_now
    end
  end
end