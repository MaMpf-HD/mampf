class MailObserver
  def self.delivered_email(message)
    logger = Logger.new("log/emails.log")
    logger.info(message)
  end
end
  
ActionMailer::Base.register_observer(MailObserver)