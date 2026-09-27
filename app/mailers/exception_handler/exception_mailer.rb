module ExceptionHandler
  class ExceptionMailer < ApplicationMailer
    # Layout
    layout "exception_mailer"

    # Defaults
    default subject: I18n.t("exception.exception",
                            host: ENV.fetch("URL_HOST"))
    default from: DefaultSetting::FROM_ADDRESS
    default template_path: "exception_handler/mailers"
    # => http://stackoverflow.com/a/18579046/1143732

    def new_exception(err)
      @exception = err
      mail(to: ExceptionHandler.config.email)
      Rails.logger.info("Exception Sent To → #{ExceptionHandler.config.email}")
    end
  end
end
