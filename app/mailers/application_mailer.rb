class ApplicationMailer < ActionMailer::Base
  default from: DefaultSetting::PROJECT_EMAIL
  default "Message-ID" => "<#{rand.to_s.split('.')[1]}.#{Time.now.to_i}@#{ENV['MAILID_DOMAIN']}>"
  layout 'mailer'
end
