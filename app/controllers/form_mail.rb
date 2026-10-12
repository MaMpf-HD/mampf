# Mails what somebody wrote into a form to the team, e.g. a support request.
# The text is stored nowhere else, so it is sent during the request: the form
# only thanks once the mail server has taken it, and otherwise shows the text
# again with a button to copy it (`form_mails/send_failed`), so that it does
# not get lost. Each user may only send so many messages in a while, so that a
# form cannot mail the team any number of times.
module FormMail
  extend ActiveSupport::Concern

  private

    # Counts one more message of the current user under `key`; true once
    # there are more than `limit` in `window`. Without the cache the count is
    # nil, and the form stays open.
    def form_mail_limit_reached?(key, limit:, window:)
      count = Rails.cache.increment(form_mail_count_key(key), 1, expires_in: window)
      count.present? && count > limit
    end

    # Sends the mail now and tells whether it went out. `deliver_now!` raises
    # on any failure, even where `raise_delivery_errors` is off. A message that
    # could not be sent does not count towards the limit. Only the kind of
    # error is logged, never the text.
    def deliver_form_mail(mail, key)
      mail.deliver_now!
      true
    rescue StandardError => e
      Rails.cache.decrement(form_mail_count_key(key), 1)
      Rails.logger.error("#{self.class.name}: mail could not be sent (#{e.class})")
      false
    end

    def form_mail_count_key(key)
      "#{key}:#{current_user.id}"
    end
end
