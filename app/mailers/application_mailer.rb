class ApplicationMailer < ActionMailer::Base
  default from: DefaultSetting::PROJECT_EMAIL
  default "Message-ID" => "#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@#{ENV["MAILSERVER"]}"
  layout 'mailer'
end
