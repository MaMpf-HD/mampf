class ApplicationMailer < ActionMailer::Base
  default from: DefaultSetting::PROJECT_EMAIL}
  layout 'mailer'
end
