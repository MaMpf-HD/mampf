# Delivers a Registration::StudentMessage from the lecture staff to all
# registered students (see Lecture#registration_mail_recipients).
#
# Note that this deliberately does not respect the email_for_announcement
# opt-out: these are operational emails tied to a registration the
# student entered themselves.
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
    # via cc; the sender is already in "to" and is not cc'd twice.
    staff_cc = ([@lecture.teacher] + @lecture.editors).uniq.map(&:email) -
               [@message.sender.email]

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
           subject: "[#{@lecture.title_for_viewers}] #{@message.subject}")
    end
  end
end
