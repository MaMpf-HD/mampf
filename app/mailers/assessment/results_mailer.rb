module Assessment
  # Tells the participants that the results of an exam or talk are
  # published. Grade and points stay out of it, since mail travels
  # unencrypted; the students read them on the lecture home.
  class ResultsMailer < ApplicationMailer
    def published_email
      @assessment = params[:assessment]
      @lecture = @assessment.lecture
      locale = params[:locale]
      I18n.with_locale(locale) do
        mail(from: NotificationMailer.sender(locale),
             bcc: User.where(id: params[:recipients]).pluck(:email),
             subject: t("assessment.results_mailer.subject", title: @assessment.title,
                                                             lecture: @lecture.title))
      end
    end
  end
end
