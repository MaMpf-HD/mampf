# SubmissionsController
class SubmissionsController < ApplicationController
  # Throttle group-join code entry so the short join token cannot be brute-forced.
  rate_limit to: 10, within: 1.minute, only: [:join, :redeem_code],
             by: -> { current_user&.id || request.remote_ip },
             with: -> { redirect_to :start, alert: I18n.t("submission.too_many_attempts") }

  before_action :set_submission, except: [:index, :new, :create, :enter_code,
                                          :redeem_code, :join, :cancel_new]
  before_action :set_assignment, only: [:new, :enter_code, :cancel_new]
  before_action :set_lecture, only: :index
  before_action :prevent_caching, only: :show_manuscript
  before_action :check_if_tutorials, only: :index
  before_action :check_student_status, only: :index
  before_action :set_disposition, only: [:show_manuscript, :show_correction]

  authorize_resource

  class TutorialNotRosteredError < StandardError; end
  rescue_from TutorialNotRosteredError do
    redirect_to :start, alert: t("submission.tutorial_not_assigned")
  end

  def current_ability
    @current_ability ||= SubmissionAbility.new(current_user)
  end

  # NOTE: authorization for #index is done manually via before_actions
  # SubmissionAbility lets anyone pass
  def index
    # Everything still open has a card above the list, so the list is what is
    # behind you - a sheet in both places would be told twice, and a row cannot
    # be handed in.
    @history = hub.sheets - hub.open_sheets

    render template: "submissions/index/index",
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  # `new` and `edit` are the same frame with the same form in it; only the
  # record differs.
  def new
    @submission = Submission.new
    @submission.assignment = @assignment
    set_submission_locale
    render_form
  end

  def edit
    render_form
  end

  def create
    @submission = Submission.new(submission_create_params)
    # authorize_resource only sees the Submission class here (no @submission is
    # preloaded for :create), so re-authorize the built instance to run the
    # enrollment check in SubmissionAbility.
    authorize! :create, @submission
    @lecture = @submission&.assignment&.lecture
    set_submission_locale
    @assignment = @submission.assignment
    return render_card(status: :unprocessable_content) if @submission.not_updatable?

    if submission_manuscript_params[:manuscript].present?
      @submission.manuscript = submission_manuscript_params[:manuscript]
      @errors = @submission.check_file_properties(@submission.manuscript
                                                             .metadata,
                                                  :manuscript)
      return render_form(status: :unprocessable_content) if @errors.present?
    end
    @submission.user_submission_joins.build(user: current_user)
    @submission.save
    @errors = @submission.errors
    return render_form(status: :unprocessable_content) unless @submission.valid?

    send_invitation_emails
    @submission.update(last_modification_by_users_at: Time.zone.now)
    if @submission.manuscript
      sync_assessment_participations(users: [current_user])
      send_upload_email(User.where(id: current_user.id))
    end
    render_card_and_standing
  end

  def update
    update_params = submission_update_params

    old_manuscript_data = @submission.manuscript_data
    @old_filename = @submission.manuscript_filename
    if submission_manuscript_params[:manuscript].present?
      @submission.manuscript = submission_manuscript_params[:manuscript]
      @errors = @submission.check_file_properties(@submission.manuscript
                                                             .metadata,
                                                  :manuscript)
      return render_form(status: :unprocessable_content) if @errors.present?

      @submission.save
      @errors = @submission.errors
      return render_form(status: :unprocessable_content) unless @submission.valid?
    end
    @submission.update(update_params)
    if @submission.valid?
      @submission.update(accepted: nil)
      if params[:submission][:detach_user_manuscript] == "true"
        @submission.update(manuscript: nil,
                           last_modification_by_users_at: Time.zone.now)
        send_upload_removal_email(@submission.users)
        clear_submitted_at(@submission.users)
      elsif @submission.manuscript_data != old_manuscript_data
        @submission.update(last_modification_by_users_at: Time.zone.now)
        send_upload_email(@submission.users)
        sync_assessment_participations
      end
    end
    @errors = @submission.errors
    return render_form(status: :unprocessable_content) if @errors.any?

    render_card_and_standing
  end

  def destroy
    clear_submitted_at(@submission.users)
    @submission.destroy
    @submission = nil
    render_card_and_standing
  end

  def enter_code
    @invites = hub.invites_for(@assignment)
  end

  def redeem_code
    code = params[:code]
    @submission = Submission.find_by(token: code)
    @assignment = @submission&.assignment
    check_code_and_join
    unless @error
      redirect_to lecture_submissions_path(@submission.tutorial.lecture),
                  notice: t("submission.joined_successfully",
                            assignment: @submission.assignment.title)
      return
    end
    redirect_to :start, alert: t("submission.failed_redemption",
                                 message: @error)
  end

  def join
    @assignment = Assignment.find_by(id: join_params[:assignment_id])
    @lecture = @assignment.lecture
    set_submission_locale
    code = join_params[:code]
    @submission = Submission.find_by(token: code, assignment: @assignment)
    check_code_and_join
    if @error
      @invites = hub.invites_for(@assignment)
      return render :enter_code, status: :unprocessable_content
    end

    render_card_and_standing
  end

  # Leaving is refused for the last person on a team - that is a delete, and it
  # is a different button. The card says so rather than quietly doing nothing.
  def leave
    if @submission.users.one?
      @card_error = I18n.t("submission.no_partners_no_leave")
      return render_card(status: :unprocessable_content)
    end
    clear_submitted_at([current_user])
    @submission.users.delete(current_user)
    send_leave_email
    @submission = nil
    render_card_and_standing
  end

  def cancel_edit
    render_card
  end

  def cancel_new
    render_card
  end

  def show_manuscript
    if @submission&.manuscript
      send_stored_file(@submission.manuscript,
                       disposition: @disposition,
                       fallback: @submission.manuscript_filename || "manuscript")
    elsif @submission
      redirect_to :start, alert: t("submission.no_manuscript_yet")
    else
      redirect_to :start, alert: t("submission.exists_no_longer")
    end
  end

  def show_correction
    if @submission&.correction
      send_stored_file(@submission.correction,
                       disposition: @disposition,
                       fallback: @submission.correction_filename || "correction")
    elsif @submission
      redirect_to :start, alert: t("submission.no_correction_yet")
    else
      redirect_to :start, alert: t("submission.exists_no_longer")
    end
  end

  def refresh_token
    @submission.update(token: Submission.generate_token)
    render_card
  end

  def enter_invitees
    @partners = hub.invitable_to(@submission)
  end

  def invite
    send_invitation_emails
    render_card
  end

  def edit_correction
  end

  def cancel_edit_correction
  end

  def add_correction
    if correction_params[:correction].present?
      @submission.correction = correction_params[:correction]
      @errors = @submission.check_file_properties_any(@submission.correction
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

    # Everything a student does changes one sheet and nothing else - the history
    # list holds only sheets that are closed - so every action answers by
    # re-rendering that sheet's card frame. Reading the whole hub back for it is
    # what keeps the card from ever disagreeing with the row below it.
    def render_card(status: :ok)
      loaded = hub
      @sheet = loaded.sheets.find { |sheet| sheet.assignment == @assignment }
      @invites = loaded.invites_for(@assignment)
      @partners = loaded.possible_partners
      render :card, status: status
    end

    # Handing in, taking it back, joining and leaving all move `submitted_at`,
    # and the standing block counts a sheet that is handed in and not yet marked
    # among the points still being marked. So these answers carry two places at
    # once, and a frame can only carry one. The data for both is already in
    # hand: the card is read from the loader either way.
    def render_card_and_standing(status: :ok)
      loaded = hub
      render turbo_stream: [
        turbo_stream.replace(SubmissionCardComponent.frame_id(@assignment),
                             card_component(loaded)),
        turbo_stream.replace(StandingComponent::TARGET,
                             StandingComponent.new(standing: loaded.standing))
      ], status: status
    end

    def card_component(loaded)
      sheet = loaded.sheets.find { |candidate| candidate.assignment == @assignment }
      SubmissionCardComponent.new(sheet: sheet,
                                  invites: loaded.invites_for(@assignment),
                                  partners: loaded.possible_partners,
                                  error: @card_error)
    end

    # The form back in the frame with its messages beside the fields, rather
    # than an alert box next to a card that still shows the old state.
    def render_form(status: :ok)
      @partners = hub.possible_partners
      render :form, status: status
    end

    def hub
      @hub ||= Assessment::SubmissionsHub::Loader.new(lecture: @lecture,
                                                      user: current_user).call
    end

    def set_submission
      @submission = Submission.find_by(id: params[:id])
      @assignment = @submission&.assignment
      @lecture = @assignment&.lecture
      set_submission_locale
      return if @submission

      # No card to put a message in, so the frame says what happened and offers
      # the way back rather than navigating itself somewhere unexpected.
      render :gone, status: :gone
    end

    def submission_create_params
      permitted = params.expect(submission: [:tutorial_id, :assignment_id])
      lecture = Assignment.find_by(id: permitted[:assignment_id])&.lecture
      return permitted unless lecture&.roster_managed?

      permitted.merge(tutorial_id: rostered_tutorial!(lecture).id)
    end

    # disallow modification of assignment
    def submission_update_params
      lecture = @submission.assignment.lecture
      # The form has no tutorial field in roster mode, so there is nothing to expect.
      return { tutorial_id: rostered_tutorial!(lecture).id } if lecture&.roster_managed?

      params.expect(submission: [:tutorial_id])
    end

    def rostered_tutorial!(lecture)
      current_user.rostered_tutorial_in(lecture) || raise(TutorialNotRosteredError)
    end

    # disallow modification of assignment
    def submission_manuscript_params
      params.expect(submission: [:manuscript])
    end

    def set_assignment
      @assignment = Assignment.find_by(id: params[:assignment_id])
      @lecture = @assignment&.lecture
      set_submission_locale
      return if @assignment

      flash.now[:alert] = I18n.t("controllers.no_assignment")
      render js: "window.location='#{root_path}'"
      nil
    end

    def set_lecture
      @lecture = Lecture.find_by(id: params[:id])
      set_submission_locale and return if @lecture

      redirect_to :root, alert: I18n.t("controllers.no_lecture")
    end

    def set_submission_locale
      I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
    end

    def join_params
      params.expect(join: [:code, :assignment_id])
    end

    def invitation_params
      params.expect(submission: [invitee_ids: []])
    end

    def correction_params
      params.expect(submission: [:correction])
    end

    def move_params
      params.expect(submission: [:tutorial_id])
    end

    def send_invitation_emails
      requested_ids = invitation_params[:invitee_ids].map(&:to_i)
      invitees = @submission.admissible_invitees(current_user)
                            .select { |i| requested_ids.include?(i.id) }
      invitees.each do |i|
        NotificationMailer.with(recipient: i,
                                locale: i.locale,
                                assignment: @assignment,
                                code: @submission.token,
                                issuer: current_user)
                          .submission_invitation_email.deliver_later
      end
      @submission.update(invited_user_ids: @submission.invited_user_ids |
                                             invitees.map(&:id))
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
        @error = I18n.t("submission.invalid_code_for_assignment",
                        assignment: @assignment.title)
      elsif !@submission
        @error = I18n.t("submission.invalid_code")
      elsif @assignment&.totally_expired?
        @error = I18n.t("submission.assignment_expired")
      elsif @submission.correction
        @error = I18n.t("submission.already_corrected")
      elsif current_user.in?(@submission.users)
        @error = I18n.t("submission.already_in")
      elsif !current_user.proper_student_in?(@submission.tutorial.lecture)
        @error = I18n.t("submission.lecture_not_subscribed")
      end
    end

    def check_code_and_join
      check_code_validity
      return if @error

      # Joining by code (which is also how an invitation is accepted) would place
      # the submission in a tutorial the user is not a member of.
      rostered_tutorial!(@assignment.lecture) if @assignment.lecture.roster_managed?

      @join = UserSubmissionJoin.new(user: current_user,
                                     submission: @submission)
      @join.save
      if @join.valid?
        @submission.update(last_modification_by_users_at: Time.zone.now)
        send_join_email
        remove_invitee_status
        sync_assessment_participations(users: [current_user]) if @submission.manuscript
      else
        @error = @join.errors[:base].join(", ")
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

      redirect_to :root,
                  alert: I18n.t("controllers.no_student_status_in_lecture")
    end

    def check_if_tutorials
      return if @lecture.tutorials.any?

      redirect_to :root, alert: I18n.t("controllers.no_tutorials_in_lecture")
    end

    def clear_submitted_at(users)
      assessment = @submission&.assignment&.assessment
      return unless assessment

      assessment.assessment_participations
                .where(user_id: users.map(&:id))
                .update_all(submitted_at: nil, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end

    def sync_assessment_participations(users: nil)
      assignment = @submission&.assignment
      assessment = assignment&.assessment
      return unless assessment

      lecture = assignment.lecture
      target_users = Array(users || @submission.users)
      member_ids = lecture.members.where(id: target_users.map(&:id)).pluck(:id)
      target_users.select! { |user| user.id.in?(member_ids) }
      return if target_users.empty?

      target_users.each do |user|
        participation = assessment.assessment_participations
                                  .find_or_initialize_by(user: user)
        participation.status = :pending
        participation.grade_numeric = nil
        participation.grade_text = nil
        participation.points_total = nil
        participation.graded_at = nil
        participation.grader_id = nil
        participation.task_points.destroy_all if participation.persisted?

        participation.submitted_at = Time.current
        participation.tutorial_id ||=
          Assessment::Participation.tutorial_for(user, lecture)
        participation.save!
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end

    def set_disposition
      @disposition = params[:download] == "true" ? "attachment" : "inline"
      accepted = @submission.assignment.accepted_file_type
      return unless accepted.in?(Assignment.non_inline_file_types)

      @disposition = "attachment"
    end
end
