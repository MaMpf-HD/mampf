class UserCleanerMailer < ApplicationMailer
  layout "warning_mail_layout"

  # Creates an email to inform a user that their account will be deleted.
  #
  # @param [Integer] num_days_until_deletion:
  #  The number of days until the account will be deleted.
  def pending_deletion_email(user_email, user_locale, num_days_until_deletion)
    sender = "#{t("mailer.warning")} <#{DefaultSetting::FROM_ADDRESS}>"
    I18n.locale = user_locale

    @num_days_until_deletion = num_days_until_deletion
    subject = t("mailer.pending_deletion_subject",
                num_days_until_deletion: @num_days_until_deletion)
    mail(from: sender, to: user_email, subject: subject, priority: "high")
  end

  # Creates an email to inform a user that their account has been deleted.
  def deletion_email(user_email, user_locale)
    sender = "#{t("mailer.warning")} <#{DefaultSetting::FROM_ADDRESS}>"
    I18n.locale = user_locale

    subject = t("mailer.deletion_subject")
    mail(from: sender, to: user_email, subject: subject, priority: "high")
  end

  # Creates an email to inform the MaMpf team that a user could not be destroyed.
  # It goes to the error address: the project address is for people writing in.
  def destroy_failed_email(user)
    sender = "UserCleaner <#{DefaultSetting::FROM_ADDRESS}>"
    subject = "User #{user.id} could not be destroyed"

    @user = user
    mail(from: sender, to: DefaultSetting::ERROR_EMAIL,
         content_type: "text/plain",
         subject: subject, priority: "high")
  end
end
