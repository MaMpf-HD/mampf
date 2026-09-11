require "net/http"
require "uri"
require "json"
# RegistrationsController
class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :check_registration_limit, only: [:create]

  def create
    altcha_param = params.permit(:altcha)[:altcha]
    if altcha_param.present? && Altcha.verify(altcha_param)
      super do |user|
        next if user.persisted?

        log_rejected_sign_up(user.errors.full_messages.to_sentence)
      end
    else
      build_resource(devise_parameter_sanitizer.sanitize(:sign_up))
      clean_up_passwords(resource)
      log_rejected_sign_up("captcha verification failed")
      flash.now[:alert] = I18n.t("devise.registrations.user.captcha_error")
      render_flash
    end
  end

  def destroy
    password_correct = resource.valid_password?(deletion_params[:password])
    unless password_correct
      set_flash_message(:alert, :password_incorrect)
      respond_with_navigational(resource) do
        redirect_to after_sign_up_path_for(resource_name)
      end
      return
    end
    success = resource.archive_and_destroy(deletion_params[:archive_name])
    unless success
      set_flash_message(:alert, :not_destroyed)
      respond_with_navigational(resource) do
        redirect_to after_sign_up_path_for(resource_name)
      end
      return
    end
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message(:notice, :destroyed)
    yield(resource) if block_given?
    respond_with_navigational(resource) do
      redirect_to after_sign_out_path_for(resource_name)
    end
  end

  protected

    def after_sign_up_path_for(_resource)
      edit_profile_path
    end

    # Devise drops blank password fields before saving, so an empty submit would
    # report success and put the user back on the same form.
    def update_resource(resource, params)
      if resource.password_change_required? && params[:password].blank?
        resource.errors.add(:password, :blank)
        return false
      end

      super
    end

    def after_update_path_for(resource)
      return super unless session[:enforce_password_change]
      return edit_user_registration_path if resource.password_change_required?

      after_password_change_path_for(resource)
    end

  private

    def check_registration_limit
      minutes = ENV.fetch("MAMPF_REGISTRATION_TIMEFRAME", 15).to_i
      timeframe = (minutes.minutes.ago..)
      num_new_registrations = User.where(confirmed_at: nil, created_at: timeframe).count
      max_registrations = ENV.fetch("MAMPF_MAX_REGISTRATION_PER_TIMEFRAME", 40).to_i
      return if num_new_registrations <= max_registrations

      # Current number of new registrations is too high
      self.resource = resource_class.new(devise_parameter_sanitizer.sanitize(:sign_up))
      resource.validate # Look for any other validation errors besides reCAPTCHA
      log_rejected_sign_up("registration limit reached: #{num_new_registrations} " \
                           "unconfirmed in the last #{minutes} min, " \
                           "max #{max_registrations}")
      set_flash_message(:alert, :too_many_registrations)
      set_minimum_password_length
      respond_with_navigational(resource) { render :new }
    end

    # A rejected sign-up is ordinary control flow, so nothing else records why
    # the form came back. Emails are filtered out of the logs, so after the
    # fact the reason is otherwise unreachable.
    def log_rejected_sign_up(reason)
      Rails.logger.info { "Sign-up rejected: #{reason}" }
    end

    def deletion_params
      params.permit(:archive_name, :password)
    end
end
