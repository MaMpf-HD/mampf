# Deletes inactive users from the database.
# See [1] for a description of how the flow works.
# [1] https://github.com/MaMpf-HD/mampf/issues/410#issuecomment-2136875776
class UserCleaner
  attr_accessor :imap, :email_dict, :hash_dict

  def inactive_users
    User.where("last_sign_in_at < ?", 6.months.ago)
  end

  def update_deletion_date_for_inactive_users
    inactive_users.where(deletion_date: nil).find_each do |user|
      user.update(deletion_date: Date.current + 40.days)
    end
  end

  def delete_users_according_to_deletion_date
    deleted_count = 0
    User.where("deletion_date <= ?", Date.current).find_each do |user|
      continue unless user.generic?

      user.destroy
      deleted_count += 1
    end
    puts "#{deleted_count} stale users deleted."
  end

  def handle_inactive_users
    update_deletion_date_for_inactive_users
    delete_users_according_to_deletion_date
  end

  ### TODO

  def login
    @imap = Net::IMAP.new(ENV.fetch("IMAPSERVER"), port: 993, ssl: true)
    @imap.authenticate("LOGIN", ENV.fetch("PROJECT_EMAIL_USERNAME"),
                       ENV.fetch("PROJECT_EMAIL_PASSWORD"))
  end

  def logout
    @imap.logout
  end

  def search_emails_and_hashes
    @email_dict = {}
    @hash_dict = {}
    @imap.examine(ENV.fetch("PROJECT_EMAIL_MAILBOX"))
    # Mails containing multiple email addresses (Subject: "Undelivered Mail Returned to Sender")
    @imap.search(["SUBJECT",
                  "Undelivered Mail Returned to Sender"]).each do |message_id|
      body = @imap.fetch(message_id,
                         "BODY[TEXT]")[0].attr["BODY[TEXT]"].squeeze(" ")
      # rubocop:disable Layout/LineLength
      next unless (match = body.scan(/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4})[\s\S]*?([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4})[\s\S]*?User has moved to ERROR: Account expired/))
      # rubocop:enable Layout/LineLength

      match = match.flatten.uniq
      match.each do |email|
        add_mail(email, message_id)

        try_get_hash(body, email)
      end
    end
    # Mails containing single email addresses (Subject: "Delivery Status Notification (Failure)")
    # define array containing all used regex patterns
    patterns = [
      '([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4})>[\s\S]*?Unknown recipient',
      # rubocop:disable Layout/LineLength
      '([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4})>[\s\S]*?User unknown in virtual mailbox table'
      # rubocop:enable Layout/LineLength
    ]

    @imap.search(["SUBJECT",
                  "Delivery Status Notification (Failure)"]).each do |message_id|
      body = @imap.fetch(message_id,
                         "BODY[TEXT]")[0].attr["BODY[TEXT]"].squeeze(" ")
      patterns.each do |pattern|
        next unless (match = body.scan(/#{pattern}/))

        match = match.flatten.uniq
        match.each do |email|
          add_mail(email, message_id)

          try_get_hash(body, email)
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
    rescue StandardError
      nil
    end
  end

  def send_hashes
    @emails = @email_dict.keys
    @users = User.where(email: @emails)

    @users.each do |user|
      user.update(ghost_hash: Digest::SHA256.hexdigest(Time.now.to_i.to_s))
      MathiMailer.ghost_email(user).deliver_now
      move_mail(@email_dict[user])
    end
  end

  def delete_ghosts
    # @hash_dict.each do |mail, hash|
    #   u = User.find_by(email: mail, ghost_hash: hash)
    #   move_mail(@email_dict[mail]) if u.present? && @email_dict.present?
    #   u.destroy! if u&.generic?
    # end
  end

  def move_mail(message_ids, attempt = 0)
    return if message_ids.blank?

    message_ids = Array(message_ids)
    return if attempt > 3

    begin
      @imap.examine(ENV.fetch("PROJECT_EMAIL_MAILBOX"))
      @imap.move(message_ids, "Other Users/mampf/handled_bounces")
    rescue Net::IMAP::BadResponseError
      move_mail(message_ids, attempt + 1)
    end
  end

  def clean!
    # TODO: Implement new user cleaner logic
    # login
    # search_emails_and_hashes
    # return if @email_dict.blank?

    # send_hashes
    # sleep(10)
    # search_emails_and_hashes
    # delete_ghosts
    # logout
  end
end
