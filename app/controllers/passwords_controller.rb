class PasswordsController < Devise::PasswordsController
  THROTTLE_WINDOW = 1.hour

  # Every request mails the address in it, whether the account exists or not.
  rate_limit to: 5, within: THROTTLE_WINDOW, only: :create,
             by: -> { "#{request.remote_ip}:#{throttle_email}" },
             with: -> { respond_with_flash(:alert, throttled_message(THROTTLE_WINDOW)) }
end
