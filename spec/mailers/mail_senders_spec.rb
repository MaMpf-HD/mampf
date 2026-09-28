require "rails_helper"

# Mail leaves from FROM_ADDRESS, notifications from PROJECT_NOTIFICATION_EMAIL.
# PROJECT_EMAIL is where people write to, so the app neither sends from it nor
# to it.
RSpec.describe("Mail senders") do
  let(:user) { create(:confirmed_user) }

  it "sends the Devise mails from the sender address" do
    email = MyMailer.confirmation_instructions(user, "token")

    expect(email.from).to eq([DefaultSetting::FROM_ADDRESS])
  end

  it "sends a support request from the sender address to the support address" do
    details = { "message" => "My exam registration does not work.", "user_id" => user.id,
                "page" => "http://localhost/lectures/1" }

    email = SupportRequestMailer.with(support_request: details).new_support_request_email

    expect(email.from).to eq([DefaultSetting::FROM_ADDRESS])
    expect(email.to).to eq([DefaultSetting::SUPPORT_EMAIL])
    expect(email.reply_to).to eq([user.email])
    expect(email.body.to_s).to include("My exam registration does not work.")
  end

  it "answers a support request from somebody not signed in at the given address" do
    details = { "message" => "I cannot sign in.", "email" => "someone@example.com" }

    email = SupportRequestMailer.with(support_request: details).new_support_request_email

    expect(email.reply_to).to eq(["someone@example.com"])
  end

  it "sends a user's data from the sender address to that user alone" do
    email = MathiMailer.data_provide_email(user)

    expect(email.from).to eq([DefaultSetting::FROM_ADDRESS])
    expect(email.to).to eq([user.email])
  end

  it "sends the user cleaner's warnings from the sender address" do
    warning = UserCleanerMailer.pending_deletion_email(user.email, "en", 7)
    deletion = UserCleanerMailer.deletion_email(user.email, "en")

    expect(warning.from).to eq([DefaultSetting::FROM_ADDRESS])
    expect(deletion.from).to eq([DefaultSetting::FROM_ADDRESS])
  end

  # Rendering the mail needs exception_handler's own exception record, built
  # from a request; the mailer's defaults are what new_exception sends with.
  it "reports an exception from the sender address to the error address" do
    expect(ExceptionHandler::ExceptionMailer.default[:from])
      .to eq(DefaultSetting::FROM_ADDRESS)
    expect(ExceptionHandler.config.email).to eq(DefaultSetting::ERROR_EMAIL)
  end

  it "reports a user that could not be destroyed to the error address" do
    email = UserCleanerMailer.destroy_failed_email(user)

    expect(email.from).to eq([DefaultSetting::FROM_ADDRESS])
    expect(email.to).to eq([DefaultSetting::ERROR_EMAIL])
  end
end
