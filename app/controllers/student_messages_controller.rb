# Lets lecture staff, and tutors for their own group, send a one-off email
# (optionally with an attachment) to the students of the groups they pick.
class StudentMessagesController < ApplicationController
  # A sender writes a handful of mails a day; a compromised account would
  # write hundreds. The cap is per sender across lectures.
  rate_limit to: 20, within: 1.hour, only: :create,
             by: -> { current_user&.id || request.remote_ip },
             with: lambda {
               redirect_to edit_lecture_path(params[:lecture_id], tab: "communication"),
                           alert: I18n.t("student_message.too_many")
             }

  before_action :set_lecture
  before_action :set_catalog

  def current_ability
    @current_ability ||= LectureAbility.new(current_user)
  end

  # How many, and whom, a selection reaches: the picker asks on every change.
  def recipients
    audiences = @catalog.pick(params[:audiences])
    return head(:forbidden) unless audiences

    render turbo_stream: turbo_stream.replace(
      "student-message-recipients",
      partial: "student_messages/recipients",
      locals: { emails: emails_of(audiences) }
    )
  end

  def create
    audiences = @catalog.pick(message_params[:audiences])
    return redirect_to(return_path, alert: t("student_message.no_audience")) if audiences.blank?

    @message = StudentMessage.new(message_params.except(:audiences, :attachment))
    @message.lecture = @lecture
    @message.sender = current_user
    @message.sender_role = @catalog.staff? ? :staff : :tutor
    @message.address_to(audiences)
    attach_scanned(message_params[:attachment])

    if @message.save
      StudentMessageMailer.with(message: @message).student_message_email.deliver_later
      redirect_to return_path, notice: t("student_message.sent", count: @message.recipients_count)
    else
      redirect_to return_path, alert: @message.errors.full_messages.to_sentence
    end
  rescue MalwareScanGate::InfectedUploadError
    redirect_to return_path, alert: t("submission.upload_failure_malware")
  rescue MalwareScanGate::ScannerUnavailableError
    redirect_to return_path, alert: t("submission.upload_failure_scanner_unavailable")
  end

  private

    def set_lecture
      @lecture = Lecture.find_by(id: params[:lecture_id])
      return if @lecture

      redirect_to root_path, alert: t("registration.lecture.not_found")
    end

    # Whoever may write to nothing in this lecture has no business here.
    def set_catalog
      @catalog = StudentMessages::Catalog.new(@lecture, current_user)
      return if @catalog.audiences.any?

      redirect_to root_path, alert: t("student_message.not_allowed")
    end

    # A file straight from the form is what the scanning attacher refuses;
    # opened here it goes through the scan like an upload, and keeps its
    # name. The block closes the handle whether the scan lets it through
    # or not.
    def attach_scanned(upload)
      return if upload.blank?

      File.open(upload.tempfile.path) do |file|
        @message.attachment_attacher.attach_cached(
          file, metadata: { "filename" => upload.original_filename }
        )
      end
    end

    def emails_of(audiences)
      User.where(id: audiences.flat_map(&:user_ids).uniq).pluck(:email)
    end

    # Where the form was: the lecture's communication tab or a tutor's page.
    # Only a path of this app is taken; anything else - another host, a
    # scheme, a string that is no URI - lands on the communication tab.
    def return_path
      given = params[:return_to].to_s
      return given if given.start_with?("/") && !given.start_with?("//", "/\\")

      edit_lecture_path(@lecture, tab: "communication")
    end

    def message_params
      params.expect(student_message: [:subject, :body, :attachment, { audiences: [] }])
    end
end
