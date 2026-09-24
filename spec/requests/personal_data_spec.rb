require "rails_helper"

RSpec.describe("Personal data", type: :request) do
  let(:user) { create(:confirmed_user, personal_data_confirmed_at: nil) }
  let(:complete) do
    { first_name: "Ada", last_name: "Lovelace", matriculation_number: "3456789",
      personal_data_confirmation: "1" }
  end

  before { sign_in(user) }

  describe "the question after sign-in" do
    it "sends a user who has neither given nor declined their data to the page" do
      get start_path

      expect(response).to redirect_to(edit_personal_data_path)
    end

    it "lets the sign-in finish before it asks" do
      sign_out(user)

      post user_session_path, params: { user: { email: user.email, password: user.password } }

      expect(response).not_to redirect_to(edit_personal_data_path)
      follow_redirect!
      expect(response).to redirect_to(edit_personal_data_path)
    end

    it "asks for a due password change first" do
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations

      get start_path

      expect(response).to redirect_to(edit_user_registration_path)
    end

    it "does not stand in the way of the upload check nginx asks for" do
      get "/internal/upload-authorizations/submission", params: { locale: user.locale }

      expect(response).to have_http_status(:no_content)
    end

    it "goes back to the page the user asked for, not to the question" do
      get lecture_path(create(:lecture, :released_for_all))
      get edit_personal_data_path
      patch personal_data_path, params: { participation: "no" }

      expect(response).not_to redirect_to(edit_personal_data_path)
    end

    it "lets a user through who has declined" do
      patch personal_data_path, params: { participation: "no" }
      get start_path

      expect(user.reload).to be_personal_data_declined
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /personal_data" do
    it "takes a no to the question as declining, whatever the fields say" do
      patch personal_data_path, params: { participation: "no", user: complete }

      expect(user.reload).to be_personal_data_declined
      expect(user.first_name).to be_nil
    end

    it "keeps the answer yes when the form comes back with errors" do
      patch personal_data_path,
            params: { participation: "yes", user: complete.except(:personal_data_confirmation) }

      expect(response.body).to match(/value="yes"[^>]*checked|checked[^>]*value="yes"/)
    end

    it "saves the data once the user confirms it" do
      patch personal_data_path, params: { user: complete }

      user.reload
      expect(user.full_name).to eq("Ada Lovelace")
      expect(user.matriculation_number).to eq("3456789")
      expect(user.personal_data_confirmed_at).to be_present
      expect(user.tutorial_name).to eq("Ada Lovelace")
    end

    it "saves nothing without the confirmation" do
      patch personal_data_path, params: { user: complete.except(:personal_data_confirmation) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.first_name).to be_nil
      expect(user.personal_data_confirmed_at).to be_nil
    end

    it "wants a matriculation number unless the user has none yet" do
      patch personal_data_path, params: { user: complete.except(:matriculation_number) }
      expect(response).to have_http_status(:unprocessable_content)

      patch personal_data_path,
            params: { user: complete.except(:matriculation_number)
                                    .merge(no_matriculation_number: "1") }
      expect(user.reload.personal_data_confirmed_at).to be_present
      expect(user.matriculation_number).to be_nil
    end

    it "refuses a matriculation number somebody else has saved" do
      create(:confirmed_user, matriculation_number: "3456789")

      patch personal_data_path, params: { user: complete }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.personal_data_confirmed_at).to be_nil
    end

    it "keeps what is saved and fills in only what is still empty" do
      patch personal_data_path,
            params: { user: complete.except(:matriculation_number)
                                    .merge(no_matriculation_number: "1") }

      patch personal_data_path,
            params: { user: { first_name: "Grace", matriculation_number: "1234567",
                              personal_data_confirmation: "1" } }

      user.reload
      expect(user.first_name).to eq("Ada")
      expect(user.matriculation_number).to eq("1234567")
    end
  end

  describe "ways off the page" do
    it "offers to sign out while the question is open" do
      get edit_personal_data_path

      expect(response.body).to include(destroy_user_session_path(locale: user.locale))
    end

    it "offers a way back to someone who declined, who may still fill it in" do
      patch personal_data_path, params: { participation: "no" }
      get edit_personal_data_path

      expect(response.body).to include(%(href="#{edit_profile_path}"))

      patch personal_data_path, params: { user: complete }
      expect(user.reload.full_name).to eq("Ada Lovelace")
    end
  end

  describe "the display name" do
    it "changes with a yes" do
      patch personal_data_path,
            params: { participation: "yes", user: complete.merge(name: "Ada L.") }

      expect(user.reload.name).to eq("Ada L.")
    end

    it "changes with a no as well" do
      patch personal_data_path, params: { participation: "no", user: { name: "Ada L." } }

      expect(user.reload.name).to eq("Ada L.")
      expect(user).to be_personal_data_declined
    end

    it "may not be left empty" do
      patch personal_data_path, params: { participation: "no", user: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload).to be_personal_data_pending
    end
  end

  describe "the Uni ID" do
    it "stays the user's to change, without the confirmation" do
      patch personal_data_path, params: { user: complete.merge(uni_id: "ab123") }
      patch personal_data_path, params: { user: { uni_id: "cd456" } }

      expect(user.reload.uni_id).to eq("cd456")
      expect(user.first_name).to eq("Ada")
    end
  end

  describe "the admin's user form" do
    let(:account) { create(:confirmed_user, first_name: "Ada", last_name: "Lovelace") }

    it "lets an admin correct the data" do
      sign_in(create(:confirmed_user, admin: true))

      patch user_path(account), params: { user: { first_name: "Augusta" } }, xhr: true

      expect(account.reload.first_name).to eq("Augusta")
    end

    it "does not let a user change their own data through it" do
      sign_in(account)

      patch user_path(account), params: { user: { name: "Ada", first_name: "Grace" } }, xhr: true

      expect(account.reload.first_name).to eq("Ada")
    end
  end
end
