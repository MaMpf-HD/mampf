require "rails_helper"

RSpec.describe("Feedbacks", type: :request) do
  let(:user) { create(:confirmed_user) }

  def send_feedback(body: "The search could find more.", can_contact: "0")
    post(feedbacks_path, params: { feedback: { body: body, can_contact: can_contact } },
                         as: :turbo_stream)
  end

  before { Rails.cache.clear }

  context "when signed in" do
    before { sign_in user }

    it "thanks for the feedback" do
      send_feedback

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("feedback.sent"))
    end

    it "mails an anonymous feedback without its author" do
      expect { send_feedback }
        .to have_enqueued_mail(FeedbackMailer, :new_feedback_email)
        .with(params: { feedback: { "body" => "The search could find more." } }, args: [])
    end

    it "mails the author along when they may be contacted" do
      expect { send_feedback(can_contact: "1") }
        .to have_enqueued_mail(FeedbackMailer, :new_feedback_email)
        .with(params: { feedback: hash_including("user_id" => user.id,
                                                 "user_email" => user.email) },
              args: [])
    end

    it "sends a too short feedback back without mailing it" do
      expect { send_feedback(body: "") }
        .not_to have_enqueued_mail(FeedbackMailer, :new_feedback_email)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "stops after the limit" do
      stub_const("FeedbacksController::LIMIT", 1)

      send_feedback
      expect { send_feedback }
        .not_to have_enqueued_mail(FeedbackMailer, :new_feedback_email)

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  context "when signed out" do
    it "does not mail anything" do
      expect { send_feedback }
        .not_to have_enqueued_mail(FeedbackMailer, :new_feedback_email)
    end
  end
end
