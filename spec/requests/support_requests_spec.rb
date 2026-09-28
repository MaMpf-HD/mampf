require "rails_helper"

RSpec.describe("SupportRequests", type: :request) do
  let(:user) { create(:confirmed_user) }

  def send_request(message: "My exam registration does not work.", email: nil)
    post(support_requests_path,
         params: { support_request: { message: message, email: email,
                                      page: "http://localhost/lectures/1" } },
         as: :turbo_stream)
  end

  before { Rails.cache.clear }

  context "when signed in" do
    before { sign_in user }

    it "mails the message to the support address, answering to the user" do
      expect { send_request }
        .to have_enqueued_mail(SupportRequestMailer, :new_support_request_email)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("support_request.sent"))
    end

    it "sends nothing for a message too short to act on" do
      expect { send_request(message: "Help") }
        .not_to have_enqueued_mail(SupportRequestMailer, :new_support_request_email)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "sends nothing for a message of spaces only" do
      expect { send_request(message: " " * 12) }
        .not_to have_enqueued_mail(SupportRequestMailer, :new_support_request_email)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "stops after five messages in an hour" do
      6.times { send_request }

      wait = ActionController::Base.helpers.distance_of_time_in_words(
        SupportRequestsController::THROTTLE_WINDOW
      )
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include(
        I18n.t("devise.failure.too_many_requests", wait: wait)
      )
    end
  end

  context "when not signed in" do
    it "takes a message with an address to answer to" do
      expect { send_request(email: "someone@example.com") }
        .to have_enqueued_mail(SupportRequestMailer, :new_support_request_email)
    end

    it "asks for the address" do
      expect { send_request }
        .not_to have_enqueued_mail(SupportRequestMailer, :new_support_request_email)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
