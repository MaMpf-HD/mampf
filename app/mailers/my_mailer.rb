class MyMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

  layout "devise_mailer"
  default template_path: "devise/mailer" # to make sure that your mailer uses the devise views
  default from: DefaultSetting::FROM_ADDRESS
  default "Message-ID" => lambda {
                            "<#{rand.to_s.split(".")[1]}.#{Time.now.to_i}@#{ENV.fetch(
                              "MAILID_DOMAIN", nil
                            )}>"
                          }
  helper EmailHelper

  # Tells the owner of an address that somebody tried to sign up with it.
  def registration_attempt(record, opts = {})
    devise_mail(record, :registration_attempt, opts)
  end
end
