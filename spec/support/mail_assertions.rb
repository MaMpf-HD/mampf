# Asserts that the given email is sent from the project notification email
# and that the display name is set to the correct value.
def assert_from_notification_mailer(mail)
  expect(mail.from).to eq([DefaultSetting::PROJECT_NOTIFICATION_EMAIL])
  expect(mail[:from].display_names).to eq([I18n.t("mailer.notification")])
end
