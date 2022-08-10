# PORO class that removes users with inactive emails
class UserCleaner
  attr_accessor :email_dict, :imap

  def login
    @imap = Net::IMAP.new(ENV['IMAPSERVER'], port: 993, ssl: true)
    @imap.authenticate('LOGIN', ENV['PROJECT_EMAIL_USERNAME'], ENV['PROJECT_EMAIL_PASSWORD'])
  end

  def logout
    @imap.logout
  end

  def search_emails
    @imap.examine(ENV['PROJECT_EMAIL_MAILBOX'])
    @imap.search(['SUBJECT', 'Undelivered Mail Returned to Sender']).each do |message_id|
      body = @imap.fetch(message_id, "BODY[TEXT]")[0].attr["BODY[TEXT]"]
      if match = body.match(/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4})>[\s\S]*?User has moved to ERROR: Account expired\./)
        match.captures.each do |email|
          add_mail(email, message_id)
        end
      end
    end
    @imap.search(['SUBJECT', 'Delivery Status Notification (Failure)']).each do |message_id|
      body = @imap.fetch(message_id, "BODY[TEXT]")[0].attr["BODY[TEXT]"]
      if match = body.match(/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4})>[\s\S]*?Unknown recipient/)
        match.captures.each do |email|
          add_mail(email, message_id)
        end
      end
    end
  end

  def hash_based_deletion
    @imap.examine(ENV['PROJECT_EMAIL_MAILBOX'])
    @imap.search(['SUBJECT', 'Ghost']).each do |message_id|
      body = @imap.fetch(message_id, "BODY[TEXT]")[0].attr["BODY[TEXT]"]
      begin
        mail = body.match(/<p>(.*)<br>/).captures
        hash = body.match(/<br>\r\n(.*)<\/p>/).captures
      rescue
        next
      end

      u = User.find_by(email: mail, ghost_hash: hash)
      if u&.generic?
        u.destroy!
      end

      move_mail(message_id)
    end
  end

  def add_mail(email, message_id)
    if @email_dict.blank?
      @email_dict = {}
    end
    if @email_dict.key?(email)
      @email_dict[email] << message_id
    else
      @email_dict[email] = [message_id]
    end
  end

  def send_hashes
    @emails = @email_dict.keys
    @users = User.where(email: @emails)

    @users.each do |user|
      user.update(ghost_hash: Digest::SHA256.hexdigest(Time.now.to_i.to_s))
      MathiMailer.ghost_email(user).deliver_now
    end
  end

  '''def destroy_users
    @emails = @email_dict.keys
    @users = User.where(email: @emails)
    @present_emails = @users.pluck(:email)
    
    @users.each(&:destroy!)

    return if @present_emails.blank?
    message_ids = @email_dict.values_at(*@present_emails).flatten(1).uniq
    move_mail(message_ids)
  end'''

  def move_mail(message_ids, attempt=0)
    return if message_ids.blank?
    message_ids = Array(message_ids)
    if attempt>3
      return
    end

    begin
      @imap.examine(ENV['PROJECT_EMAIL_MAILBOX'])
      @imap.move(message_ids, "Other Users/mampf/handled_bounces")
    rescue Net::IMAP::BadResponseError
      move_mail(message_ids, attempt=attempt+1)
    end
  end

  def clean!
    login
    search_emails
    return if @email_dict.blank?
    send_hashes
    hash_based_deletion
    logout
  end

end