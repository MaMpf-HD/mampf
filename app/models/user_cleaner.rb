# PORO class that removes users with inactive emails
class UserCleaner
  attr_accessor :imap, :email_dict, :hash_dict

  def login
    @imap = Net::IMAP.new(ENV['IMAPSERVER'], port: 993, ssl: true)
    @imap.authenticate('LOGIN', ENV['PROJECT_EMAIL_USERNAME'], ENV['PROJECT_EMAIL_PASSWORD'])
  end

  def logout
    @imap.logout
  end

  def search_emails_and_hashes
    @email_dict = {}
    @hash_dict = {}
    @imap.examine(ENV['PROJECT_EMAIL_MAILBOX'])
    # Mails containing multiple email addresses (Subject: "Undelivered Mail Returned to Sender")
    @imap.search(['SUBJECT', 'Undelivered Mail Returned to Sender']).each do |message_id|
      body = @imap.fetch(message_id, "BODY[TEXT]")[0].attr["BODY[TEXT]"].squeeze(" ")
      if match = body.scan(/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4})[\s\S]*?([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4})[\s\S]*?User has moved to ERROR: Account expired/)
        match = match.flatten.uniq
        match.each do |email|
          add_mail(email, message_id)

          try_get_hash(body, email)
        end
      end
    end
    # Mails containing single email addresses (Subject: "Delivery Status Notification (Failure)")
    # define array containing all used regex patterns
    patterns = [
      '([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4})>[\s\S]*?Unknown recipient',
      '([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4})>[\s\S]*?User unknown in virtual mailbox table'
    ]

    @imap.search(['SUBJECT', 'Delivery Status Notification (Failure)']).each do |message_id|
      body = @imap.fetch(message_id, "BODY[TEXT]")[0].attr["BODY[TEXT]"].squeeze(" ")
      patterns.each do |pattern|
        if match = body.scan(/#{pattern}/)
          match = match.flatten.uniq
          match.each do |email|
            add_mail(email, message_id)

            try_get_hash(body, email)
          end
        end
      end
    end
  end

  def add_mail(email, message_id)
    @email_dict = {} if @email_dict.blank?
    if @email_dict.key?(email)
      @email_dict[email] << message_id
    else
      @email_dict[email] = [message_id]
    end
  end

  def try_get_hash(body, email)
    @hash_dict = {} if @hash_dict.blank?
    begin
      hash = body.match(/Hash:([a-zA-Z0-9]*)/).captures
      @hash_dict[email] = hash
    rescue
      return
    end
  end

  def send_hashes
    @emails = @email_dict.keys
    @users = User.where(email: @emails)

    @users.each do |user|
      user.update(ghost_hash: Digest::SHA256.hexdigest(Time.now.to_i.to_s))
      MathiMailer.ghost_email(user).deliver_later
      move_mail(@email_dict[user])
    end
  end

  def delete_ghosts
    @hash_dict.each do |mail, hash|
      u = User.find_by(email: mail, ghost_hash: hash)
      move_mail(@email_dict[mail]) if u.present? and @email_dict.present?
      u.destroy! if u&.generic?
    end
  end

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
    search_emails_and_hashes
    return if @email_dict.blank?
    send_hashes
    sleep(10)
    search_emails_and_hashes
    delete_ghosts
    logout
  end

end