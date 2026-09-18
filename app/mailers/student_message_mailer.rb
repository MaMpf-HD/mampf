# Delivers a StudentMessage to the groups its sender picked.
#
# Note that this deliberately does not respect the email_for_announcement
# opt-out: these are operational emails tied to a group the student is in.
class StudentMessageMailer < ApplicationMailer
  def student_message_email
    @message = params[:message]
    @lecture = @message.lecture
    # Recipients were snapshotted when the message was created, so the
    # delivery reaches exactly the audience (and count) the sender saw.
    recipients = @message.recipient_emails
    return if recipients.empty?

    if @message.attachment.present?
      attachments[@message.attachment_filename || "attachment"] =
        @message.attachment.read
    end

    # The whole lecture staff (teacher and editors) is kept in the loop
    # via cc; the sender is already in "to" and is not cc'd twice. A
    # tutor's mail to their group is theirs alone.
    staff_cc = if @message.staff?
      ([@lecture.teacher] + @lecture.editors).uniq.map(&:email) - [@message.sender.email]
    else
      []
    end

    I18n.with_locale(@lecture.locale_with_inheritance || I18n.default_locale) do
      # The sender goes into "to" so that they get a copy of their own
      # message (and so that the mail has a proper To: header despite all
      # students being in bcc).
      mail(from: "#{t("mailer.notification")} " \
                 "<#{DefaultSetting::PROJECT_NOTIFICATION_EMAIL}>",
           to: @message.sender.email,
           cc: staff_cc,
           reply_to: @message.sender.email,
           bcc: recipients,
           subject: "[#{subject_prefix}] #{@message.subject}")
    end
  end

  private

    # A tutor's mail names the group in the subject: the lecture alone would
    # read like the lecturer's.
    def subject_prefix
      return @lecture.title_for_viewers if @message.staff?

      "#{@lecture.title_for_viewers}, #{@message.audience_labels.to_sentence}"
    end
end
