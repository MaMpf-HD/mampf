class PasswordsController < Devise::PasswordsController
  THROTTLE_WINDOW = 1.hour

  # Without a limit, anyone could use this form to send any number of mails to
  # any address.
  rate_limit to: 5, within: THROTTLE_WINDOW, only: :create,
             by: -> { "#{request.remote_ip}:#{throttle_email}" },
             with: -> { respond_with_flash(:alert, throttled_message(THROTTLE_WINDOW)) }

  skip_before_action :require_no_authentication, only: :restart

  def restart
    sign_out(resource_name) if user_signed_in?

    redirect_to new_user_password_path(locale: params[:locale])
  end

  def after_resetting_password_path_for(resource)
    return super unless session[:enforce_password_change]

    session.delete(:enforce_password_change)
    stored_location_for(resource_name).presence || start_path
  end
end
