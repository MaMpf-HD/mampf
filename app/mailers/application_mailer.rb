class ApplicationMailer < ActionMailer::Base
  helper EmailHelper
  default from: DefaultSetting::PROJECT_EMAIL
  default "Message-ID" => lambda {
                            "<#{rand.to_s.split(".")[1]}.#{Time.now.to_i}@#{ENV.fetch(
                              "MAILID_DOMAIN", nil
                            )}>"
                          }
  layout "mailer"
end
