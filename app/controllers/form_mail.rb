# Mails what somebody wrote into a form to the team during the request. The
# text is stored nowhere else, so if the mail fails, the form shows the text
# again with a button to copy it (`form_mails/send_failed`).
module FormMail
  extend ActiveSupport::Concern

  private

    # Counts one more message of the current user under `key`; true once there
    # are more than `limit` in `window`, so that a form cannot mail the team any
    # number of times. Without a cache the count is nil and nobody is limited.
    def form_mail_limit_reached?(key, limit:, window:)
      count = Rails.cache.increment(form_mail_count_key(key), 1, expires_in: window)
      count.present? && count > limit
    end

    # `deliver_now!` raises even where `raise_delivery_errors` is off. A mail
    # that failed does not count towards the limit, and only its error class is
    # logged, never the text.
    def deliver_form_mail(mail, key)
      mail.deliver_now!
      true
    rescue StandardError => e
      Rails.cache.decrement(form_mail_count_key(key), 1)
      Rails.logger.error("#{self.class.name}: mail could not be sent (#{e.class})")
      false
    end

    def form_mail_sender
      { "user_id" => current_user.id,
        "user_name" => current_user.tutorial_name,
        "user_email" => current_user.email }
    end

    def form_mail_count_key(key)
      "#{key}:#{current_user.id}"
    end
end
