# The gem sends its mails from the address they go to. Like every other mail,
# they leave from the app's sender, the account the SMTP login belongs to.
Rails.application.config.to_prepare do
  ExceptionHandler::ExceptionMailer.default(from: DefaultSetting::FROM_ADDRESS)
end
