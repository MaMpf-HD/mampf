class UnlocksController < Devise::UnlocksController
  THROTTLE_WINDOW = 1.hour

  # Every request mails the address in it, and anyone can lock a stranger out.
  rate_limit to: 5, within: THROTTLE_WINDOW, only: :create,
             by: -> { "#{request.remote_ip}:#{throttle_email}" },
             with: -> { respond_with_flash(:alert, throttled_message(THROTTLE_WINDOW)) }
end
