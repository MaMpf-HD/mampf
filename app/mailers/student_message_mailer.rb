# Delivers a StudentMessage to the groups its sender picked.
#
# Note that this deliberately does not respect the email_for_announcement
# opt-out: these are operational emails tied to a group the student is in.
class StudentMessageMailer < ApplicationMailer
  # Sends one mail per language the recipients read. Only the mail in the
  # sender's language carries the sender's copy and the staff's cc, and it
  # goes out even without recipients: nobody gets the message twice.
  def self.deliver_by_locale(message)
    groups = message.recipient_emails_by_locale
    sender_locale = (message.sender.locale.presence || I18n.default_locale).to_s
    groups[sender_locale] ||= []
    groups.each do |locale, emails|
      with(message: message, locale: locale, recipients: emails - message.copy_emails,
           copies: locale == sender_locale).student_message_email.deliver_later
    end
  end

  # A job queued by an older release carries only the message: that mail
  # goes to everybody at once, in the lecture's language.
  def student_message_email
    @message = params[:message]
    @lecture = @message.lecture
    # The saved addresses, not the groups as they are now: a change in
    # between must not retarget a queued mail.
    return if @message.recipient_emails.empty?

    recipients = params.fetch(:recipients) { @message.recipient_emails }
    copies = params.fetch(:copies, true)
    locale = params[:locale] || @lecture.locale_with_inheritance || I18n.default_locale

    if @message.attachment.present?
      attachments[@message.attachment_filename || "attachment"] =
        @message.attachment.read
    end

    # The whole lecture staff (teacher and editors) is kept in the loop
    # via cc; the sender is already in "to" and is not cc'd twice. A
    # tutor's mail to their group is theirs alone.
    staff_cc = copies ? @message.copy_emails - [@message.sender.email] : []

    I18n.with_locale(locale) do
      # The sender goes into "to" so that they get a copy of their own
      # message (and so that the mail has a proper To: header despite all
      # students being in bcc).
      mail(from: "#{t("mailer.notification")} " \
                 "<#{DefaultSetting::PROJECT_NOTIFICATION_EMAIL}>",
           to: copies ? @message.sender.email : DefaultSetting::PROJECT_NOTIFICATION_EMAIL,
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
