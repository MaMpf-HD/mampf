# Across all sources, one address gets at most ten mails a day from the
# password reset, confirmation and unlock forms together, so that requests
# from many machines cannot flood a stranger's inbox either. The forms share
# one count because they send each other's mails: the unlock form sends the
# password reset when nothing is locked. `rate_limit` would count each
# controller on its own.
module AddressMailLimit
  extend ActiveSupport::Concern

  ADDRESS_WINDOW = 1.day
  ADDRESS_LIMIT = 10

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
