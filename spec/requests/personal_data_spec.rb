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

    it "returns to a page, not to a background request" do
      get start_path(format: :json)

      patch personal_data_path, params: { participation: "no" }

      expect(response).to redirect_to(start_path)
    end

    it "leaves account deletion and the consent to the terms open" do
      get delete_account_path, xhr: true
      expect(response).to have_http_status(:ok)

      get consent_profile_path
      expect(response).not_to redirect_to(edit_personal_data_path)
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

    it "wants the matriculation number as seven digits" do
      patch personal_data_path, params: { user: complete.merge(matriculation_number: "345678") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("must be seven digits")

      patch personal_data_path, params: { user: complete.merge(matriculation_number: "345 6789") }
      expect(user.reload.matriculation_number).to eq("3456789")
    end

    it "saves no number when the user ticked that they have none yet" do
      patch personal_data_path,
            params: { user: complete.merge(no_matriculation_number: "1") }

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

  describe "a student with places" do
    let(:lecture) { create(:lecture, :released_for_all) }
    let(:tutorial) { create(:tutorial, lecture: lecture) }

    before do
      tutorial.add_user_to_roster!(user)
      lecture.add_user_to_roster!(user)
    end

    it "is shown the lectures instead of a plain no" do
      get edit_personal_data_path

      expect(response.body).to include(lecture.title)
      expect(response.body).to include(I18n.t("personal_data.places_no"))
      expect(response.body).not_to include(I18n.t("personal_data.participation_question"))
    end

    it "is asked again after a no, for a place that came afterwards" do
      tutorial.remove_user_from_roster!(user)
      lecture.remove_user_from_roster!(user)
      patch personal_data_path, params: { participation: "no" }
      tutorial.add_user_to_roster!(user)

      get start_path

      expect(response).to redirect_to(edit_personal_data_path)
    end

    it "leaves out the first-sign-in profile notice when it asks again after a no" do
      get start_path
      sign_out(user)
      user.update!(personal_data_declined_at: Time.current, sign_in_count: 0)

      post user_session_path, params: { user: { email: user.email, password: user.password } }

      expect(flash[:notice]).to be_nil
      follow_redirect!
      expect(response).to redirect_to(edit_personal_data_path)
    end

    it "gives the places up with the no, once the form has named them" do
      patch personal_data_path, params: { participation: "no", give_up_places: lecture.id.to_s }

      expect(user.reload).to be_personal_data_declined
      expect(tutorial.reload.members).not_to include(user)
      expect(lecture.reload.members).not_to include(user)
      get start_path
      expect(response).to have_http_status(:ok)
    end

    it "keeps the places when the form did not name them" do
      patch personal_data_path, params: { participation: "no" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("personal_data.places_changed"))
      expect(user.reload).to be_personal_data_pending
      expect(tutorial.reload.members).to include(user)
    end

    it "asks for the details without offering to give up once results are recorded" do
      create(:assessment_participation, :reviewed, user: user)

      get edit_personal_data_path

      expect(response.body).to include(I18n.t("personal_data.places_results"))
      expect(response.body).not_to include(I18n.t("personal_data.places_no"))
    end

    it "asks again after a no when a result is recorded later, with the fields only" do
      tutorial.remove_user_from_roster!(user)
      lecture.remove_user_from_roster!(user)
      patch personal_data_path, params: { participation: "no" }
      create(:assessment_participation, :reviewed, user: user)

      get start_path
      follow_redirect!

      expect(response.body).to include(I18n.t("personal_data.places_results"))
      expect(response.body).not_to include('name="participation"')
    end

    it "keeps the places and the question when a no comes despite recorded results" do
      create(:assessment_participation, :reviewed, user: user)

      patch personal_data_path, params: { participation: "no", give_up_places: lecture.id.to_s }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("personal_data.places_graded"))
      expect(user.reload).to be_personal_data_pending
      expect(tutorial.reload.members).to include(user)
    end

    it "keeps every place when one was added after the form named the others" do
      other = create(:lecture)
      allow(Rosters::MaintenanceService).to receive(:new).and_wrap_original do |original|
        other.add_user_to_roster!(user) unless other.members.include?(user)
        original.call
      end

      patch personal_data_path, params: { participation: "no", give_up_places: lecture.id.to_s }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("personal_data.places_changed"))
      expect(user.reload).to be_personal_data_pending
      expect(tutorial.reload.members).to include(user)
    end

    it "keeps the places with a yes" do
      patch personal_data_path, params: { participation: "yes", user: complete }

      expect(user.reload.personal_data_confirmed_at).to be_present
      expect(tutorial.reload.members).to include(user)
    end
  end

  describe "the language chosen on the page" do
    it "becomes the user's language, so an error or the way back keeps it" do
      user.update!(locale: "en")

      get edit_personal_data_path(locale: "de")
      patch personal_data_path, params: { user: complete.except(:first_name) }

      expect(user.reload.locale).to eq("de")
      expect(response.body).to include("Vorname")
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

  describe "the study program" do
    let(:math) { create(:subject, name: "Mathematik", key: Subject::MATH) }
    let!(:program) { create(:program, subject: math, name: "B.Sc. 50%", degree: :bsc50) }

    it "comes as a step of its own once there are programs to pick" do
      get edit_personal_data_path

      expect(response.body).to include("Step 3 of 5: Study program")
    end

    it "is saved with the rest" do
      patch personal_data_path, params: { user: complete.merge(program_id: program.id) }

      expect(user.reload.program).to eq(program)
    end

    it "stays empty for another program" do
      patch personal_data_path, params: { user: complete.merge(program_id: "") }

      expect(user.reload.personal_data_confirmed_at).to be_present
      expect(user.program).to be_nil
    end

    it "refuses a program that only classifies courses" do
      sorting = create(:program, subject: math, name: "Seminare")

      patch personal_data_path, params: { user: complete.merge(program_id: sorting.id) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.program).to be_nil
    end

    it "is the mathematics one for a student of two subjects who says so" do
      patch personal_data_path,
            params: { study_degree: "bsc50", study_math: "yes",
                      user: complete.merge(program_id: "") }

      expect(user.reload.program).to eq(program)
    end

    it "does not stand in the way once its program is no longer offered" do
      patch personal_data_path, params: { user: complete.merge(program_id: program.id) }
      program.update!(degree: nil)

      expect(user.reload.update(locale: "de")).to be(true)
    end

    it "stays the user's to change, without the confirmation" do
      master = create(:program, subject: math, name: "M.Sc.", degree: :msc)
      patch personal_data_path, params: { user: complete.merge(program_id: program.id) }

      patch personal_data_path, params: { user: { program_id: master.id } }

      expect(user.reload.program).to eq(master)
    end
  end

  describe "the logs" do
    it "leave out every personal detail" do
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      details = { "first_name" => "Ada", "last_name" => "Lovelace",
                  "matriculation_number" => "3456789", "uni_id" => "ab123", "program_id" => "4" }

      expect(filter.filter("user" => details)["user"].values).to all(eq("[FILTERED]"))
    end
  end

  describe "the profile" do
    it "lists all details the user has given" do
      program = create(:program, subject: create(:subject, name: "Mathematik"), name: "M.Sc.",
                                 degree: :msc)
      patch personal_data_path,
            params: { user: complete.merge(program_id: program.id, uni_id: "ab123") }

      get edit_profile_path

      expect(response.body).to include("Ada Lovelace", "3456789", "Mathematik: M.Sc.", "ab123")
    end
  end

  describe "the Uni ID" do
    it "takes two letters and three digits, not an email address" do
      patch personal_data_path, params: { user: complete.merge(uni_id: "ada@uni-heidelberg.de") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("must be two letters followed by three digits")

      patch personal_data_path, params: { user: complete.merge(uni_id: " AB123 ") }
      expect(user.reload.uni_id).to eq("ab123")
    end

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

    it "does not offer the fields to a teacher editing their own account" do
      create(:lecture, teacher: account)
      sign_in(account)

      get elevated_profile_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('name="user[first_name]"')
    end

    it "does not let a teacher change their own data through it" do
      create(:lecture, teacher: account)
      sign_in(account)

      patch user_path(account), params: { user: { name: "Ada L.", first_name: "Grace" } },
                                xhr: true

      expect(account.reload.name).to eq("Ada L.")
      expect(account.first_name).to eq("Ada")
    end
  end
end
