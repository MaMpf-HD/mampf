require "rails_helper"

RSpec.describe("Feedbacks", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:body) { "The search could find more." }

  def send_feedback(body: self.body)
    post(feedbacks_path, params: { feedback: { body: body } }, as: :turbo_stream)
  end

  def sent_mails
    ActionMailer::Base.deliveries
  end

  before do
    Rails.cache.clear
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("FEEDBACK_EMAIL").and_return("feedback@example.com")
  end

  context "when signed in" do
    before { sign_in user }

    it "thanks once the feedback is mailed" do
      expect { send_feedback }.to change(sent_mails, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("feedback.sent"))
    end

    it "mails the feedback to the feedback address, to be answered to its author" do
      send_feedback

      expect(sent_mails.last.to).to eq(["feedback@example.com"])
      expect(sent_mails.last.subject).to eq("Feedback: #{user.email}")
      expect(sent_mails.last.reply_to).to eq([user.email])
      expect(sent_mails.last.body.encoded).to include(user.email)
    end

    context "when the mail cannot be sent" do
      before do
        allow_any_instance_of(Mail::TestMailer)
          .to receive(:deliver!).and_raise(Net::SMTPServerBusy)
      end

      it "does not thank, but offers to copy the feedback" do
        send_feedback

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body).not_to include(I18n.t("feedback.sent"))
        expect(response.body).to include(I18n.t("form_mail.send_failed").squish)

        page = Nokogiri::HTML(response.body)
        expect(page.at_css("[data-clipboard-text-value]")["data-clipboard-text-value"])
          .to eq(body)
        expect(page.at_css("textarea").text.strip).to eq(body)
      end

      it "does not count the feedback towards the limit" do
        stub_const("FeedbacksController::LIMIT", 1)
        send_feedback

        allow_any_instance_of(Mail::TestMailer).to receive(:deliver!).and_call_original
        expect { send_feedback }.to change(sent_mails, :count).by(1)
      end
    end

    it "sends a too short feedback back without mailing it" do
      expect { send_feedback(body: "Meh") }.not_to change(sent_mails, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "stops after the limit" do
      stub_const("FeedbacksController::LIMIT", 1)

      send_feedback
      expect { send_feedback }.not_to change(sent_mails, :count)

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  context "when signed in but asked for personal data or a new password first" do
    it "mails the feedback of a user whose personal data is still due" do
      sign_in create(:confirmed_user, personal_data_confirmed_at: nil)

      expect { send_feedback }.to change(sent_mails, :count).by(1)
    end

    it "mails the feedback of a user who must change the password" do
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      sign_in user

      expect { send_feedback }.to change(sent_mails, :count).by(1)
    end
  end

  context "when signed out" do
    it "does not mail anything" do
      expect { send_feedback }.not_to change(sent_mails, :count)
    end
  end
end
