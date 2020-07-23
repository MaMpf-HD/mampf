class MyMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views
  default from: DefaultSetting::PROJECT_EMAIL
  default "Message-ID" => -> {"<#{rand.to_s.split('.')[1]}.#{Time.now.to_i}@#{ENV['MAILID_DOMAIN']}>" }
  add_template_helper(EmailHelper)
end
