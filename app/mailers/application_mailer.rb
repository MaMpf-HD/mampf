class ApplicationMailer < ActionMailer::Base
  default from: DefaultSetting::PROJECT_EMAIL
  default "Message-ID" => "<#{self.object_id}.#{Time.now.to_i}@#{ENV['MAILID_DOMAIN']}>"
  layout 'mailer'
end
