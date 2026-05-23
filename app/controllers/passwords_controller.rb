class PasswordsController < Devise::PasswordsController
  prepend_before_action :enable_password_strength_validation, only: [:update]

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
