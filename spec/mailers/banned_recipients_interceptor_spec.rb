require "rails_helper"

RSpec.describe(BannedRecipientsInterceptor, type: :mailer) do
  let(:admin) { create(:confirmed_user, admin: true) }
  let(:banned) { create(:confirmed_user, email: "banned@example.org") }
  let(:other) { create(:confirmed_user, email: "emmy@example.org") }

  before do
    banned.ban(by: admin, reason: "Misuse of exam data")
    ActionMailer::Base.deliveries.clear
  end

  it "leaves a banned account out of a mail to several and sends it to the rest" do
    announcement = create(:announcement, announcer: admin)

    NotificationMailer.with(recipients: [banned.id, other.id], announcement: announcement)
                      .announcement_email.deliver_now

    expect(ActionMailer::Base.deliveries.map(&:bcc)).to eq([["emmy@example.org"]])
  end

  it "sends nothing when only banned accounts were addressed" do
    banned.send_reset_password_instructions

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "finds the address whatever its case and keeps the other recipients' names" do
    message = Mail.new(to: "Emmy Noether <emmy@example.org>, Banned@Example.org",
                       cc: "banned@example.org")

    BannedRecipientsInterceptor.delivering_email(message)

    expect(message[:to].to_s).to eq("Emmy Noether <emmy@example.org>")
    expect(message[:cc]).to be_nil
    expect(message.perform_deliveries).to be(true)
  end

  it "counts a new address that waits for confirmation" do
    banned.update_column(:unconfirmed_email, "new@example.org") # rubocop:disable Rails/SkipsModelValidations
    message = Mail.new(to: "new@example.org")

    BannedRecipientsInterceptor.delivering_email(message)

    expect(message.perform_deliveries).to be(false)
  end

  it "sends again once the ban is lifted" do
    banned.unban

    banned.send_reset_password_instructions

    expect(ActionMailer::Base.deliveries.map(&:to)).to eq([["banned@example.org"]])
  end
end
