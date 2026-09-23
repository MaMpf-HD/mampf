# Lets lecture staff, and tutors for their own group, send a one-off email
# (optionally with an attachment) to the students of the groups they pick.
class StudentMessagesController < ApplicationController
  before_action :set_lecture
  before_action :set_catalog
  # A per-sender cap on bulk mail, across lectures. Declared after the
  # catalog so that a refused sender is sent back to their own page.
  rate_limit to: 20, within: 1.hour, only: :create,
             by: -> { current_user.id },
             with: -> { redirect_to return_path, alert: I18n.t("student_message.too_many") }

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
    @message.address_to(audiences, labels: @catalog.labels_by_locale(audiences.map(&:key)))
    attach_scanned(message_params[:attachment])

    if @message.save
      StudentMessageMailer.deliver_by_locale(@message)
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
      @catalog = StudentMessages::Catalog.new(@lecture, current_user).tap(&:audiences)
      return if @catalog.audiences.any?

      redirect_to root_path, alert: t("student_message.not_allowed")
    end

    # A file straight from the form is what the scanning attacher refuses;
    # opened here it goes through the scan like an upload, and keeps its
    # name. In a block: a scan that refuses raises before Shrine would
    # close it.
    def attach_scanned(upload)
      return if upload.blank?
      raise(ActionController::BadRequest) unless upload.respond_to?(:tempfile)

      File.open(upload.tempfile.path) do |file|
        @message.attachment_attacher.attach_cached(
          file, metadata: { "filename" => upload.original_filename }
        )
      end
    end

    def emails_of(audiences)
      StudentMessages::Audience.recipients(audiences).pluck(:email)
    end

    # Where the form was, or the sender's own page. Both forms hand over a
    # path of this app; a value that is not one is not followed, so that a
    # bad one cannot fail the redirect once the message is on its way.
    def return_path
      given = params[:return_to].to_s
      return given if app_path?(given)

      if @catalog.staff?
        edit_lecture_path(@lecture, tab: "communication")
      else
        lecture_tutorials_path(@lecture)
      end
    end

    def app_path?(given)
      return false unless given.start_with?("/") && !given.start_with?("//") && given.size <= 2000

      uri = URI.parse(given)
      uri.scheme.nil? && uri.host.nil?
    rescue URI::InvalidURIError
      false
    end

    def message_params
      params.expect(student_message: [:subject, :body, :attachment, { audiences: [] }])
    end
end
