class UnlocksController < Devise::UnlocksController
  THROTTLE_WINDOW = 1.hour

  # Throttle unlock-resend so a single source cannot email-bomb an address:
  # anyone can lock an account with five wrong passwords and then have the
  # unlock mail sent again on every request (AUTH-H02).
  rate_limit to: 5, within: THROTTLE_WINDOW, only: :create,
             by: -> { "#{request.remote_ip}:#{params.dig(:user, :email).to_s.downcase}" },
             with: -> { respond_with_flash(:alert, throttled_message(THROTTLE_WINDOW)) }
end
