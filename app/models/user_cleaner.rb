# PORO class that removes users with inactive emails
class UserCleaner
  attr_accessor :emails

  def login
    @imap = Net::IMAP.new(ENV['IMAPSERVER'], port: 993, ssl: true)
    @imap.authenticate('LOGIN', ENV['PROJECT_EMAIL_USERNAME'], ENV['PROJECT_EMAIL_PASSWORD'])
  end

  def search_emails
    @imap.examine(ENV['PROJECT_EMAIL_MAILBOX'])
    @imap.search(['SUBJECT', 'Undelivered Mail Returned to Sender']).each do |message_id|
      body = imap.fetch(message_id, "BODY[TEXT]")[0].attr["BODY[TEXT]"]
      @emails = body.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}>\): User has moved to ERROR: Account expired\./)
      @emails.each do |email|
        email.sub!('>): User has moved to ERROR: Account expired.', '')
      end

      @emails += body.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}>[\s\S]*Unknown recipient/)
    end
  end

  def destroy_users
    @users = User.where(email: @emails)
    @users.each(&:destroy!)
  end

  def clean!
    login
    search_emails
    destroy_users
  end

end