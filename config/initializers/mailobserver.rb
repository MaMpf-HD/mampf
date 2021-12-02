class MailObserver
  def self.delivered_email(message)
    logger = Logger.new("my_log.txt")
    logger.info(message)
  end
end
  
ActionMailer::Base.register_observer(MailObserver)