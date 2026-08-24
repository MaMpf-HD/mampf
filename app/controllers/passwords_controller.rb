class PasswordsController < Devise::PasswordsController
  THROTTLE_WINDOW = 1.hour

  # Throttle reset requests so a single source cannot email-bomb an address:
  # `paranoid` hides whether the address exists, but Devise still sends the
  # mail on each request (AUTH-H02).
  rate_limit to: 5, within: THROTTLE_WINDOW, only: :create,
             by: -> { "#{request.remote_ip}:#{throttle_email}" },
             with: -> { respond_with_flash(:alert, throttled_message(THROTTLE_WINDOW)) }

  prepend_before_action :enable_password_strength_validation, only: [:update]

  def update
    super
  end

  private

    def enable_password_strength_validation
      return unless Rails.env.test?

      Current.password_strength_validation_enabled = true
    end
end
