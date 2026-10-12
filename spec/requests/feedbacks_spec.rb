require "rails_helper"

RSpec.describe("Feedbacks", type: :request) do
  let(:user) { create(:confirmed_user) }

  def send_feedback(body: "The search could find more.")
    post(feedbacks_path, params: { feedback: { body: body } }, as: :turbo_stream)
  end

  before { Rails.cache.clear }

  context "when signed in" do
    before { sign_in user }

    it "stores the feedback without its author" do
      expect { send_feedback }.to change(Feedback, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("feedback.sent"))
      expect(Feedback.last.attributes.keys).not_to include("user_id")
    end

    it "sends a too short feedback back" do
      expect { send_feedback(body: "") }.not_to change(Feedback, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "stops after the limit" do
      stub_const("FeedbacksController::LIMIT", 1)

      send_feedback
      expect { send_feedback }.not_to change(Feedback, :count)

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  context "when signed out" do
    it "does not store anything" do
      expect { send_feedback }.not_to change(Feedback, :count)
    end
  end
end
