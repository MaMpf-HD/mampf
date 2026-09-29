require "rails_helper"

RSpec.describe("SupportRequests", type: :request) do
  let(:user) { create(:confirmed_user) }

  def send_request(message: "My exam registration does not work.")
    post(support_requests_path, params: { support_request: { message: message } },
                                as: :turbo_stream)
  end

  before { Rails.cache.clear }

  context "when signed in" do
    before { sign_in user }

    it "mails the message" do
      expect { send_request }
        .to have_enqueued_mail(SupportRequestMailer, :new_support_request_email)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("support_request.sent"))
    end

    # A second question should not need a new page.
    it "offers an empty form for the next message" do
      send_request

      form = Nokogiri::HTML(response.body).at_css("form[action='#{support_requests_path}']")
      expect(form.at_css("textarea").text.strip).to be_empty
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

    it "stops after the messages an hour allows" do
      SupportRequestsController::LIMIT.times { send_request }
      expect(response).to have_http_status(:ok)

      expect { send_request }
        .not_to have_enqueued_mail(SupportRequestMailer, :new_support_request_email)

      wait = ActionController::Base.helpers.distance_of_time_in_words(
        SupportRequestsController::THROTTLE_WINDOW
      )
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include(I18n.t("devise.failure.too_many_requests", wait: wait))
    end

    # Otherwise a few mistakes would lock somebody out of the support.
    it "does not count a message sent back for a mistake" do
      (SupportRequestsController::LIMIT + 1).times { send_request(message: "Help") }

      expect { send_request }
        .to have_enqueued_mail(SupportRequestMailer, :new_support_request_email)
    end
  end

  context "when signed in but asked for personal data or a new password first" do
    it "mails the message of a user whose personal data is still due" do
      sign_in create(:confirmed_user, personal_data_confirmed_at: nil)

      expect { send_request }
        .to have_enqueued_mail(SupportRequestMailer, :new_support_request_email)
    end

    it "mails the message of a user who must change the password" do
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      sign_in user

      expect { send_request }
        .to have_enqueued_mail(SupportRequestMailer, :new_support_request_email)
    end
  end

  # Without an account there is no address we know to be theirs; the button
  # shows them where to write instead.
  context "when not signed in" do
    it "takes no message" do
      expect { send_request }
        .not_to have_enqueued_mail(SupportRequestMailer, :new_support_request_email)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows where to write instead of a form" do
      get new_user_session_path

      panel = Nokogiri::HTML(response.body).at_css("#support-request-body")
      expect(panel.at_css("textarea")).to be_nil
      expect(panel.at_css("a[href='mailto:#{DefaultSetting::PROJECT_EMAIL}']")).to be_present
    end
  end
end
