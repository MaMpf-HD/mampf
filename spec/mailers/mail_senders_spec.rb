require "rails_helper"

# The machine sends from FROM_ADDRESS; PROJECT_EMAIL is where people write to,
# so nothing automatic may leave from it or land in it.
RSpec.describe("Mail senders") do
  let(:user) { create(:confirmed_user) }

  it "sends the Devise mails from the sender address" do
    email = MyMailer.confirmation_instructions(user, "token")

    expect(email.from).to eq([DefaultSetting::FROM_ADDRESS])
  end

  it "sends feedback from the sender address to the feedback address" do
    feedback = Feedback.create!(user: user, title: "Idea", feedback: "A longer idea text",
                                can_contact: true)

    email = FeedbackMailer.with(feedback: feedback).new_user_feedback_email

    expect(email.from).to eq([DefaultSetting::FROM_ADDRESS])
    expect(email.to).to eq([DefaultSetting::FEEDBACK_EMAIL])
    expect(email.reply_to).to eq([user.email])
  end

  it "sends a data request from the sender address to the project address" do
    email = MathiMailer.data_request_email(user)

    expect(email.from).to eq([DefaultSetting::FROM_ADDRESS])
    expect(email.to).to eq([DefaultSetting::PROJECT_EMAIL])
  end

  it "sends the user cleaner's warnings from the sender address" do
    email = UserCleanerMailer.pending_deletion_email(user.email, "en", 7)

    expect(email.from).to eq([DefaultSetting::FROM_ADDRESS])
  end

  it "reports a user that could not be destroyed to the error address" do
    email = UserCleanerMailer.destroy_failed_email(user)

    expect(email.from).to eq([DefaultSetting::FROM_ADDRESS])
    expect(email.to).to eq([DefaultSetting::ERROR_EMAIL])
  end
end
