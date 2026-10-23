# Pauses the password reset, confirmation and unlock mails to one address for
# ten minutes, whichever machine asks, so nobody can flood a stranger's inbox.
# A pause rather than a daily cap, which anybody could use up to keep the
# owner out for a day. The forms share one count because the unlock form
# sends the password reset when nothing is locked; `rate_limit` would count
# each controller on its own.
module AddressMailLimit
  extend ActiveSupport::Concern

  ADDRESS_WINDOW = 10.minutes
  ADDRESS_LIMIT = 1

  included do
    before_action :limit_mails_to_address, if: -> { action_name == "create" }
  end

  private

    def limit_mails_to_address
      return if throttle_email.blank?

      count = cache_store.increment("rate-limit:account-mails:#{throttle_email}", 1,
                                    expires_in: ADDRESS_WINDOW)
      return unless count && count > ADDRESS_LIMIT

      respond_with_flash(:alert, throttled_message(ADDRESS_WINDOW))
    end
end
