class PasswordsController < Devise::PasswordsController
  THROTTLE_WINDOW = 1.hour
  ADDRESS_WINDOW = 1.day

  # Without a limit, anyone could use this form to send any number of mails to
  # any address.
  rate_limit to: 5, within: THROTTLE_WINDOW, only: :create,
             by: -> { "#{request.remote_ip}:#{throttle_email}" },
             with: -> { respond_with_flash(:alert, throttled_message(THROTTLE_WINDOW)) }

  # Across all sources, one address gets at most ten of these mails a day, so
  # that requests from many machines cannot flood a stranger's inbox either.
  rate_limit to: 10, within: ADDRESS_WINDOW, only: :create, name: "address",
             if: -> { throttle_email.present? }, by: -> { throttle_email },
             with: -> { respond_with_flash(:alert, throttled_message(ADDRESS_WINDOW)) }

  skip_before_action :require_no_authentication, only: :restart

  def restart
    sign_out(resource_name) if user_signed_in?

    redirect_to new_user_password_path(locale: params[:locale])
  end

  protected

    def after_resetting_password_path_for(resource)
      return super unless session[:enforce_password_change]

      after_password_change_path_for(resource)
    end
end
