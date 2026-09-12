class ConfirmationsController < Devise::ConfirmationsController
  THROTTLE_WINDOW = 1.hour

  # Without a limit, anyone could use this form to send any number of mails to
  # any address.
  rate_limit to: 5, within: THROTTLE_WINDOW, only: :create,
             by: -> { "#{request.remote_ip}:#{throttle_email}" },
             with: -> { respond_with_flash(:alert, throttled_message(THROTTLE_WINDOW)) }
end
