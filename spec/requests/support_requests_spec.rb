require "rails_helper"

RSpec.describe("SupportRequests", type: :request) do
  let(:user) { create(:confirmed_user) }

  def send_request(message: "My exam registration does not work.")
    post(support_requests_path, params: { support_request: { message: message } },
                                as: :turbo_stream)
  end

  def sent_mails
    ActionMailer::Base.deliveries
  end

  before { Rails.cache.clear }

  context "when signed in" do
    before { sign_in user }

    it "mails the message" do
      expect { send_request }
        .to change(sent_mails, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("support_request.sent"))
    end

    # The mail carries the message, the name and the address; the log at
    # production's level (info) must not.
    it "keeps the message and the sender out of the log" do
      log = StringIO.new
      logger = ActiveSupport::Logger.new(log, level: :info)
      allow(ActionMailer::Base).to receive(:logger).and_return(logger)
      allow(ActionController::Base).to receive(:logger).and_return(logger)

      send_request(message: "My exam registration for Noether's lecture fails.")

      expect(log.string).to include("SupportRequestsController")
      expect(log.string).not_to include("Noether", user.email)
    end

    context "when the mail cannot be sent" do
      before do
        allow_any_instance_of(Mail::TestMailer)
          .to receive(:deliver!).and_raise(Net::SMTPServerBusy)
      end

      it "keeps the message and offers to copy it" do
        send_request

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body).not_to include(I18n.t("support_request.sent"))
        expect(response.body).to include(I18n.t("form_mail.send_failed").squish)

        page = Nokogiri::HTML(response.body)
        expect(page.at_css("[data-clipboard-text-value]")["data-clipboard-text-value"])
          .to eq("My exam registration does not work.")
        expect(page.at_css("textarea").text.strip).to eq("My exam registration does not work.")
      end

      it "does not count the message towards the limit" do
        SupportRequestsController::LIMIT.times { send_request }
        allow_any_instance_of(Mail::TestMailer).to receive(:deliver!).and_call_original

        expect { send_request }.to change(sent_mails, :count).by(1)
      end
    end

    # A second question should not need a new page.
    it "offers an empty form for the next message" do
      send_request

      form = Nokogiri::HTML(response.body).at_css("form[action='#{support_requests_path}']")
      expect(form.at_css("textarea").text.strip).to be_empty
    end

    it "sends nothing for a message too short to act on" do
      expect { send_request(message: "Help") }
        .not_to change(sent_mails, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "sends nothing for a message of spaces only" do
      expect { send_request(message: " " * 12) }
        .not_to change(sent_mails, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "stops after the messages an hour allows" do
      SupportRequestsController::LIMIT.times { send_request }
      expect(response).to have_http_status(:ok)

      expect { send_request }
        .not_to change(sent_mails, :count)

      wait = ActionController::Base.helpers.distance_of_time_in_words(
        SupportRequestsController::THROTTLE_WINDOW
      )
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include(I18n.t("devise.failure.too_many_requests", wait: wait))
    end

    it "takes messages when the cache is down" do
      allow(Rails.cache).to receive(:increment).and_return(nil)

      expect { send_request }
        .to change(sent_mails, :count).by(1)
    end

    # Otherwise a few mistakes would lock somebody out of the support.
    it "does not count a message sent back for a mistake" do
      (SupportRequestsController::LIMIT + 1).times { send_request(message: "Help") }

      expect { send_request }
        .to change(sent_mails, :count).by(1)
    end
  end

  context "when signed in but asked for personal data or a new password first" do
    it "mails the message of a user whose personal data is still due" do
      sign_in create(:confirmed_user, personal_data_confirmed_at: nil)

      expect { send_request }
        .to change(sent_mails, :count).by(1)
    end

    it "mails the message of a user who must change the password" do
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      sign_in user

      expect { send_request }
        .to change(sent_mails, :count).by(1)
    end
  end

  # Without an account there is no address we know to be theirs; the button
  # shows them where to write instead.
  context "when not signed in" do
    it "takes no message" do
      expect { send_request }
        .not_to change(sent_mails, :count)

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
