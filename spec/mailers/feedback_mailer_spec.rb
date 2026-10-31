require "rails_helper"

RSpec.describe(FeedbackMailer) do
  subject(:mail) { described_class.with(feedback: feedback).new_feedback_email }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("FEEDBACK_EMAIL").and_return("feedback@example.com")
  end

  let(:feedback) do
    { "body" => "The search could find more.", "user_id" => 42,
      "user_name" => "Emmy Noether", "user_email" => "emmy@example.com" }
  end

  it "goes to the feedback address" do
    expect(mail.to).to eq(["feedback@example.com"])
  end

  it "sets the author as reply-to" do
    expect(mail.reply_to).to eq(["emmy@example.com"])
  end

  it "names the author" do
    expect(mail.subject).to eq("Feedback: emmy@example.com")
    expect(mail.body.encoded).to include("Emmy Noether", "emmy@example.com", "id 42",
                                         "The search could find more.")
  end
end
