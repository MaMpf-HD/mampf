module Assessment
  # Tells a participant that the results of an exam or talk are published.
  # Grade and points stay out of it, since mail travels unencrypted; the
  # student reads them on the lecture home.
  class ResultsMailer < ApplicationMailer
    def published_email
      @recipient = params[:recipient]
      @assessment = params[:assessment]
      @lecture = @assessment.lecture
      @name = @recipient.tutorial_name
      I18n.with_locale(@recipient.locale || I18n.default_locale) do
        mail(from: NotificationMailer.sender(@recipient.locale), to: @recipient.email,
             subject: t("assessment.results_mailer.subject", title: @assessment.title,
                                                             lecture: @lecture.title))
      end
    end
  end
end
