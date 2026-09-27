require "rails_helper"

RSpec.describe("Auth registrations", type: :request) do
  include ActiveSupport::Testing::TimeHelpers

  before do
    ActionMailer::Base.deliveries.clear
  end

  describe "POST /users" do
    let(:email) { "signup_#{SecureRandom.hex(4)}@example.com" }
    let(:base_params) do
      {
        user: {
          email: email,
          password: "super-secure-horse-battery-staple",
          password_confirmation: "super-secure-horse-battery-staple",
          consents: "1",
          locale: "en"
        }
      }
    end

    it "creates an unconfirmed user when captcha validation succeeds" do
      allow(Altcha).to receive(:verify).and_return(true)

      expect do
        post(user_registration_path, params: base_params.merge(altcha: "valid"))
      end.to change(User, :count).by(1)

      created_user = User.order(:id).last
      expect(created_user.email).to eq(email)
      expect(created_user).not_to be_confirmed
      expect(ActionMailer::Base.deliveries.last.to).to include(email)
    end

    it "does not create a user without consent to the privacy policy" do
      allow(Altcha).to receive(:verify).and_return(true)
      params = base_params.merge(altcha: "valid")
      params[:user] = params[:user].except(:consents)

      expect do
        post(user_registration_path, params: params)
      end.not_to change(User, :count)
    end

    it "does not create a user when captcha validation fails" do
      allow(Altcha).to receive(:verify).and_return(false)

      expect do
        post(user_registration_path,
             params: base_params.merge(altcha: "invalid"),
             as: :turbo_stream)
      end.not_to change(User, :count)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(I18n.t("devise.registrations.user.captcha_error"))
      expect(response.body).to include('target="registration-captcha"')
    end

    it "lets a sign-up through when the page was open longer than a challenge lasts" do
      get new_user_registration_path
      travel 10.minutes

      get captcha_challenge_path
      challenge = response.parsed_body
      number = (0..challenge["maxnumber"]).find do |n|
        Digest::SHA256.hexdigest("#{challenge["salt"]}#{n}") == challenge["challenge"]
      end
      solution = Base64.strict_encode64(
        challenge.slice("algorithm", "challenge", "salt", "signature")
                 .merge("number" => number).to_json
      )

      expect do
        post(user_registration_path, params: base_params.merge(altcha: solution))
      end.to change(User, :count).by(1)
    end

    it "blocks sign up when the registration limit is exceeded" do
      allow(Altcha).to receive(:verify).and_return(true)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("MAMPF_REGISTRATION_TIMEFRAME", 15).and_return("15")
      allow(ENV).to receive(:fetch).with("MAMPF_MAX_REGISTRATION_PER_TIMEFRAME", 40).and_return("0")
      create(:user, created_at: 1.minute.ago)

      expect do
        post(user_registration_path, params: base_params.merge(altcha: "valid"))
      end.not_to change(User, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("devise.registrations.user.too_many_registrations"))
    end

    describe "with an address that already has an account" do
      let!(:owner) { create(:confirmed_user, email: "owner@example.com", locale: "en") }

      before do
        allow(Altcha).to receive(:verify).and_return(true)
        Rails.cache.clear
      end

      def sign_up_with(address, **overrides)
        params = base_params.merge(altcha: "valid")
        params[:user] = params[:user].merge(email: address, **overrides)
        post(user_registration_path, params: params)
        [response.status, response.location, flash[:notice]]
      end

      it "answers exactly as for a new address" do
        new_answer = sign_up_with(email)

        expect do
          expect(sign_up_with("Owner@example.com ")).to eq(new_answer)
        end.not_to change(User, :count)
      end

      it "tells the owner by mail, in their language" do
        owner.update!(locale: "de")

        sign_up_with("owner@example.com")

        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq(["owner@example.com"])
        expect(mail.subject).to eq("Du hast schon ein MaMpf-Konto")
      end

      it "sends the owner at most one notice an hour" do
        3.times { sign_up_with("owner@example.com") }

        expect(ActionMailer::Base.deliveries.count { |m| m.to == ["owner@example.com"] })
          .to eq(1)
      end

      it "sends an owner who never confirmed the confirmation mail again" do
        owner.update!(confirmed_at: nil)

        sign_up_with("owner@example.com")

        expect(ActionMailer::Base.deliveries.last.subject)
          .to eq(I18n.t("devise.mailer.confirmation_instructions.subject", locale: "en"))
      end

      it "still names the other mistakes, but never the taken address" do
        sign_up_with("owner@example.com", password_confirmation: "something-else-entirely")

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).not_to include(I18n.t("errors.messages.taken"))
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    describe "records why a sign-up was rejected" do
      # Nothing raises on a rejected sign-up and emails are filtered out of the
      # logs, so an operator can only see the reason if we log it on purpose.
      def info_logs_while
        logged = []
        allow(Rails.logger).to receive(:info) do |*args, &block|
          logged << (block ? block.call : args.first).to_s
        end
        yield
        logged.join("\n")
      end

      it "names the validation errors" do
        allow(Altcha).to receive(:verify).and_return(true)
        params = base_params.merge(altcha: "valid")
        params[:user] = params[:user].except(:consents)

        logs = info_logs_while { post(user_registration_path, params: params) }

        # The attribute name carries the reason and is not translated, so this
        # holds in either locale while still naming which validation failed.
        expect(logs).to include("Sign-up rejected: Consents")
      end

      it "names a failed captcha" do
        allow(Altcha).to receive(:verify).and_return(false)

        logs = info_logs_while do
          post(user_registration_path,
               params: base_params.merge(altcha: "invalid"),
               as: :turbo_stream)
        end

        expect(logs).to include("Sign-up rejected: captcha verification failed")
      end

      it "names the exceeded registration limit" do
        allow(Altcha).to receive(:verify).and_return(true)
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("MAMPF_REGISTRATION_TIMEFRAME", 15).and_return("15")
        allow(ENV).to receive(:fetch).with("MAMPF_MAX_REGISTRATION_PER_TIMEFRAME", 40)
                                     .and_return("0")
        create(:user, created_at: 1.minute.ago)

        logs = info_logs_while do
          post(user_registration_path, params: base_params.merge(altcha: "valid"))
        end

        expect(logs).to include("registration limit reached")
      end
    end
  end

  describe "DELETE /users" do
    it "deletes the account when the password is correct" do
      user = create(:confirmed_user_en)
      sign_in user

      expect do
        delete(user_registration_path, params: { password: user.password })
      end.to change(User, :count).by(-1)

      expect(response).to redirect_to(root_path)

      get edit_profile_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "keeps the account when the password is incorrect" do
      user = create(:confirmed_user_en)
      sign_in user

      expect do
        delete(user_registration_path, params: { password: "wrong-password" })
      end.not_to change(User, :count)

      expect(response).to redirect_to(edit_profile_path)
      expect(user.reload).to be_present
    end
  end

  describe "PUT /users" do
    it "stores a pending email change for reconfirmation" do
      user = create(:confirmed_user_en)
      new_email = "pending_#{SecureRandom.hex(4)}@example.com"

      sign_in user

      put user_registration_path, params: {
        user: {
          email: new_email,
          current_password: user.password,
          password: "",
          password_confirmation: ""
        }
      }

      expect(user.reload.email).not_to eq(new_email)
      expect(user.unconfirmed_email).to eq(new_email)
      expect(ActionMailer::Base.deliveries.last.to).to include(new_email)
    end

    it "redirects stale users away from authenticated pages until their password changes" do
      user = create(:confirmed_user_en)
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      sign_in user

      get news_path

      expect(response).to redirect_to(edit_user_registration_path)
    end

    it "offers a way out while the change is due" do
      user = create(:confirmed_user_en)
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      sign_in user

      get edit_user_registration_path

      expect(response.body).to include(destroy_user_session_path(locale: :en))

      delete destroy_user_session_path

      expect(controller.current_user).to be_nil
    end

    it "says so when the required password is left blank" do
      password = "zitrone-diskette-vorhang-42"
      user = create(:confirmed_user_en, password: password)
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      sign_in user

      put user_registration_path,
          params: { user: { current_password: password, password: "",
                            password_confirmation: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(CGI.escapeHTML(I18n.t("errors.messages.blank")))
      expect(flash[:notice]).to be_nil
    end

    it "refuses the old password as the new one while a change is due" do
      password = "zitrone-diskette-vorhang-42"
      user = create(:confirmed_user_en, password: password)
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      sign_in user

      put user_registration_path,
          params: { user: { current_password: password,
                            password: password,
                            password_confirmation: password } }

      expect(response.body).to include(I18n.t("errors.messages.password_unchanged"))
      expect(user.reload).to be_password_change_required
    end

    it "sends a first-time user to their profile once the new password is set" do
      user = create(:confirmed_user_en, password: "zitrone-diskette-vorhang-42")
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil,
                          sign_in_count: 0)
      # rubocop:enable Rails/SkipsModelValidations

      post user_session_path, params: { user: { email: user.email,
                                                password: "zitrone-diskette-vorhang-42" } }
      put user_registration_path,
          params: { user: { current_password: "zitrone-diskette-vorhang-42",
                            password: "andere-melone-tafel-77",
                            password_confirmation: "andere-melone-tafel-77" } }

      expect(response).to redirect_to(edit_profile_path)
    end

    it "lets a frame request leave its frame instead of swapping in the prompt" do
      user = create(:confirmed_user_en)
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      sign_in user

      get news_path, headers: { "Turbo-Frame" => "some-frame" }

      expect(response.body)
        .to include('<meta name="turbo-visit-control" content="reload">')
    end

    it "shows the forced password change prompt for stale users" do
      user = create(:confirmed_user_en)
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      sign_in user

      get edit_user_registration_path

      expect(response.body)
        .to include(I18n.t("devise.edit.password_change_required"))
      expect(response.body).not_to include(I18n.t("devise.edit.email"))
    end

    it "does not allow password_policy_version to be changed through update params" do
      user = create(:confirmed_user_en)
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      sign_in user

      put user_registration_path, params: {
        user: {
          email: user.email,
          current_password: user.password,
          password: "",
          password_confirmation: "",
          password_policy_version: User::CURRENT_PASSWORD_POLICY_VERSION
        }
      }

      expect(user.reload.password_policy_version).to eq(0)
      expect(user).to be_password_change_required
    end
  end

  describe "GET /users/edit" do
    it "renders stable back and language switch links" do
      user = create(:confirmed_user_en)
      sign_in user

      get edit_user_registration_path(locale: :en)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(edit_profile_path)
      expect(response.body).to include(edit_user_registration_path(locale: :de))
    end

    it "points the language switch at the form after a failed update" do
      user = create(:confirmed_user_en)
      sign_in user

      put user_registration_path(locale: :en), params: {
        user: { email: user.email, current_password: "not-the-password",
                password: "", password_confirmation: "" }
      }

      switch_target = response.body[%r{<div id="language-switch".*?</div>}m]
                              .to_s[/href="([^"]*)"/, 1]
      expect(switch_target).to include(edit_user_registration_path)
    end

    it "keeps the switched locale across a submit" do
      user = create(:confirmed_user_en, password: "correct-horse-battery-staple")
      sign_in user

      get edit_user_registration_path(locale: :de)
      form_action = response.body[/action="([^"]*users[^"]*)"/, 1].sub("&amp;", "&")

      put form_action, params: {
        user: { email: user.email, current_password: "not-the-password",
                password: "", password_confirmation: "" }
      }

      expect(response.body).to include(I18n.with_locale(:de) { I18n.t("devise.edit.title") })
    end

    it "switches locale for signed-in users when a locale param is provided" do
      user = create(:confirmed_user_en)
      sign_in user

      get edit_user_registration_path(locale: :de)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.with_locale(:de) { I18n.t("devise.edit.title") })
      expect(user.reload.locale).to eq("en")
    end
  end
end
