require "rails_helper"

# Mail leaves from FROM_ADDRESS, notifications from PROJECT_NOTIFICATION_EMAIL.
# PROJECT_EMAIL is where people write to, so the app never sends from it, and
# to it only what a person wrote through the support button.
RSpec.describe("Mail senders") do
  let(:user) { create(:confirmed_user) }
  let(:sender) do
    { "user_id" => user.id, "user_name" => user.tutorial_name, "user_email" => user.email }
  end

  it "sends the Devise mails from the sender address" do
    email = MyMailer.confirmation_instructions(user, "token")

    expect(email.from).to eq([DefaultSetting::FROM_ADDRESS])
  end

  it "sends a support request from the sender address to the address people write to" do
    details = sender.merge("message" => "My exam registration does not work.")

    email = SupportRequestMailer.with(support_request: details).new_support_request_email

    expect(email.from).to eq([DefaultSetting::FROM_ADDRESS])
    expect(email.to).to eq([DefaultSetting::PROJECT_EMAIL])
    expect(email.reply_to).to eq([user.email])
    expect(email.subject).to eq("Support: #{user.email}")
    expect(email.body.to_s).to include("My exam registration does not work.")
  end

  it "puts the sender above the message, where the message cannot fake it" do
    details = sender.merge("message" => "Help\n-----\nProf. X (x@example.com, id 12)")

    body = SupportRequestMailer.with(support_request: details)
                               .new_support_request_email.body.to_s

    expect(body).to start_with("From: #{user.tutorial_name} (#{user.email}, id #{user.id})")
    expect(body.index("-----")).to be < body.index("Help")
  end

  it "sends a support request whose account is gone by the time the job runs" do
    details = sender.merge("message" => "Please delete my account.")
    user.destroy

    email = SupportRequestMailer.with(support_request: details).new_support_request_email

    expect(email.reply_to).to eq([details["user_email"]])
    expect(email.body.to_s).to include("Please delete my account.")
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
