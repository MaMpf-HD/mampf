class UserCleanerMailer < ApplicationMailer
  layout "warning_mail_layout"

  # Creates an email to inform a user that their account will be deleted.
  #
  # @param [Integer] num_days_until_deletion:
  #  The number of days until the account will be deleted.
  def pending_deletion_email(num_days_until_deletion)
    user = params[:user]
    sender = "#{t("mailer.warning")} <#{DefaultSetting::PROJECT_EMAIL}>"
    I18n.locale = user.locale

    @num_days_until_deletion = num_days_until_deletion
    subject = t("mailer.pending_deletion_subject",
                num_days_until_deletion: @num_days_until_deletion)
    mail(from: sender, to: user.email, subject: subject, priority: "high")
  end
end
