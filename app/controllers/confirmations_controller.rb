class ConfirmationsController < Devise::ConfirmationsController
  # Throttle confirmation-resend so a single source cannot email-bomb an
  # address: `paranoid` hides whether the address exists, but Devise still
  # sends the mail on each request (AUTH-H02).
  rate_limit to: 5, within: 1.hour, only: :create,
             by: -> { "#{request.remote_ip}:#{params.dig(:user, :email).to_s.downcase}" },
             with: -> { respond_with_flash(:alert, I18n.t("devise.failure.too_many_requests")) }

  private

    def after_confirmation_path_for(_resource_name, resource)
      sign_in(resource) # In case you want to sign in the user
      edit_profile_path
    end
end
