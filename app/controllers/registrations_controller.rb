require "net/http"
require "uri"
require "json"
# RegistrationsController
class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :check_registration_limit, only: [:create]

  def verify_captcha
    return true unless ENV["USE_CAPTCHA_SERVICE"]

    begin
      uri = URI.parse(ENV.fetch("CAPTCHA_VERIFY_URL"))
      data = { message: params["frc-captcha-solution"],
               application_token: ENV.fetch("CAPTCHA_APPLICATION_TOKEN") }
      header = { "Content-Type": "text/json" }
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if ENV.fetch("CAPTCHA_VERIFY_URL").include?("https")
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = data.to_json

      # Send the request
      response = http.request(request)
      answer = JSON.parse(response.body)
      return true if answer["message"] == "verified"
    rescue StandardError # rubocop:todo Lint/SuppressedException
    end
    false
  end

  def create
    if verify_captcha
      super
    else
      build_resource(devise_parameter_sanitizer.sanitize(:sign_up))
      clean_up_passwords(resource)
      set_flash_message(:alert, :captcha_error)
      render :new
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

  def after_sign_up_path_for(_resource)
    edit_profile_path
  end

  private

    def check_registration_limit
      timeframe = ((ENV["MAMPF_REGISTRATION_TIMEFRAME"] || 15).to_i.minutes.ago..)
      num_new_registrations = User.where(confirmed_at: nil, created_at: timeframe).count
      max_registrations = (ENV["MAMPF_MAX_REGISTRATION_PER_TIMEFRAME"] || 40).to_i
      return if num_new_registrations <= max_registrations

      # Current number of new registrations is too high
      self.resource = resource_class.new(devise_parameter_sanitizer.sanitize(:sign_up))
      resource.validate # Look for any other validation errors besides reCAPTCHA
      set_flash_message(:alert, :too_many_registrations)
      set_minimum_password_length
      respond_with_navigational(resource) { render :new }
    end

    def deletion_params
      params.permit(:archive_name, :password)
    end
end
