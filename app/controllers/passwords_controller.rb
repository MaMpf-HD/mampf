class PasswordsController < Devise::PasswordsController
  skip_before_action :require_no_authentication, only: :restart
  prepend_before_action :enable_password_strength_validation, only: [:update]

  def restart
    sign_out(resource_name) if user_signed_in?

    redirect_to new_user_password_path(locale: params[:locale])
  end

  def update
    super
  end

  def after_resetting_password_path_for(resource)
    return super unless session[:enforce_password_change]

    session.delete(:enforce_password_change)
    stored_location_for(resource_name).presence || start_path
  end

  private

    def enable_password_strength_validation
      return unless Rails.env.test?

      Current.password_strength_validation_enabled = true
    end
end
