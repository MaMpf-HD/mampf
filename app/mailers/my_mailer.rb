class MyMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views
  default from: DefaultSetting::PROJECT_EMAIL
  default "Message-ID" => "#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@mathi.uni-heidelberg.de}"
end