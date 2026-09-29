require "rails_helper"

RSpec.describe("Support users", type: :request) do
  let(:support) { create(:confirmed_user_en, support: true) }
  let!(:student) do
    create(:confirmed_user, first_name: "Emmy", last_name: "Noether",
                            matriculation_number: "1234567", email: "emmy@example.org")
  end

  def search(**fields)
    get(support_users_path, params: { search: { all_programs: "1", **fields } })
  end

  describe "who gets in" do
    it "lets the support and admins search and correct" do
      [support, create(:confirmed_user_en, admin: true)].each do |user|
        sign_in(user)

        get edit_support_user_path(student)

        expect(response).to have_http_status(:ok)
      end
    end

    it "keeps teachers and students out, corrections included" do
      teacher = create(:confirmed_user_en)
      create(:lecture, teacher: teacher)
      [teacher, create(:confirmed_user_en)].each do |user|
        sign_in(user)

        get support_users_path
        expect(response).to redirect_to(root_path)

        patch support_user_path(student), params: { user: { last_name: "Lasker" } }
        expect(student.reload.last_name).to eq("Noether")
      end
    end
  end

  describe "the search" do
    before { sign_in(support) }

    it "lists nobody before anything is asked for" do
      get support_users_path

      expect(response.body).not_to include("emmy@example.org")
    end

    it "puts the person first by matriculation number, last name or address" do
      create(:confirmed_user, last_name: "Hilbert", email: "david@example.org")

      ["1234567", "Noether", "emmy@example"].each do |query|
        search(fulltext: query)

        first_row = Nokogiri::HTML(response.body).at_css("#support-user-results tbody tr")
        expect(first_row.text).to include("emmy@example.org")
      end
    end

    it "narrows the search to a program" do
      program = create(:program, degree: "msc")
      student.update!(program: program)
      create(:confirmed_user, email: "other@example.org",
                              program: create(:program, degree: "msc"))

      get support_users_path, params: { search: { program_ids: [program.id] } }

      expect(response.body).to include("emmy@example.org")
      expect(response.body).not_to include("other@example.org")
    end
  end

  describe "a correction" do
    before { sign_in(support) }

    it "saves all of the personal data, the fields a person sets themselves included" do
      program = create(:program, degree: :msc)

      patch support_user_path(student),
            params: { user: { last_name: "Noether-Lasker", matriculation_number: "7654321",
                              program_id: program.id, uni_id: "ab123", name: "Emmy N.",
                              name_in_tutorials: "Emmy" } }

      expect(response).to redirect_to(edit_support_user_path(student))
      expect(student.reload).to have_attributes(last_name: "Noether-Lasker",
                                                matriculation_number: "7654321",
                                                program: program, uni_id: "ab123",
                                                name: "Emmy N.", name_in_tutorials: "Emmy")
    end

    # Otherwise changing the address, then sending a reset mail, would hand
    # the account to whoever typed it.
    it "keeps a new address waiting until its owner confirms it" do
      ActionMailer::Base.deliveries.clear

      patch support_user_path(student), params: { user: { email: "noether@example.org" } }

      expect(ActionMailer::Base.deliveries.map(&:to)).to eq([["noether@example.org"]])
      expect(student.reload).to have_attributes(email: "emmy@example.org",
                                                unconfirmed_email: "noether@example.org")
      follow_redirect!
      expect(response.body).to include("noether@example.org gets a link")
    end

    it "does not hand out rights" do
      patch support_user_path(student), params: { user: { last_name: "Lasker", admin: "1",
                                                          support: "1" } }

      expect(student.reload).to have_attributes(last_name: "Lasker", admin: false,
                                                support: false)
    end

    it "refuses a matriculation number somebody else has" do
      create(:confirmed_user, matriculation_number: "7654321")

      patch support_user_path(student), params: { user: { matriculation_number: "7654321" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(student.reload.matriculation_number).to eq("1234567")
    end

    it "names the error when a field outside the form keeps the user from saving" do
      student.homepage = "not a url"
      student.save(validate: false)

      patch support_user_path(student), params: { user: { last_name: "Lasker" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nothing was saved:", "Homepage")
    end

    it "says so when nothing has changed" do
      patch support_user_path(student), params: { user: { last_name: "Noether" } }
      follow_redirect!

      expect(response.body).to include("Nothing has changed.")
    end

    it "lets the support correct their own data" do
      patch support_user_path(support), params: { user: { last_name: "Kowalewskaja" } }

      expect(support.reload.last_name).to eq("Kowalewskaja")
    end

    it "keeps the support away from an admin's account" do
      admin = create(:confirmed_user, admin: true, last_name: "Klein")
      ActionMailer::Base.deliveries.clear

      patch support_user_path(admin), params: { user: { last_name: "Lie" } }
      post password_reset_support_user_path(admin)

      expect(admin.reload.last_name).to eq("Klein")
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "keeps the search for the way back" do
      patch support_user_path(student, search: { fulltext: "Noether" }),
            params: { user: { last_name: "Lasker" } }

      expect(response)
        .to redirect_to(edit_support_user_path(student, search: { fulltext: "Noether" }))
    end
  end

  describe "the account" do
    before { sign_in(support) }

    it "shows a lock and lifts it" do
      student.update_columns(locked_at: 5.minutes.ago, failed_attempts: 5) # rubocop:disable Rails/SkipsModelValidations

      get edit_support_user_path(student)
      expect(response.body).to include("5 failed sign-ins")

      patch unlock_support_user_path(student)

      expect(student.reload).to have_attributes(locked_at: nil, failed_attempts: 0)
    end

    # The mails the forms limit per address go out anyway: the support is
    # there for whoever has used them up.
    it "sends a password reset mail" do
      ActionMailer::Base.deliveries.clear

      post password_reset_support_user_path(student)

      expect(ActionMailer::Base.deliveries.map(&:to)).to eq([["emmy@example.org"]])
      expect(student.reload.reset_password_sent_at).to be_present
    end

    it "sends the confirmation mail again to an unconfirmed account" do
      unconfirmed = create(:user, email: "sofia@example.org")
      ActionMailer::Base.deliveries.clear

      post confirmation_support_user_path(unconfirmed)

      expect(ActionMailer::Base.deliveries.map(&:to)).to eq([["sofia@example.org"]])
    end

    it "offers the confirmation mail only while something waits for confirmation" do
      get edit_support_user_path(student)

      expect(response.body).not_to include("Send the confirmation mail again")
    end
  end

  describe "the admin's switch" do
    let(:account) { create(:confirmed_user) }

    it "lets an admin make somebody the support" do
      sign_in(create(:confirmed_user, admin: true))

      patch support_user_path(account), params: { user: { support: "1" } }

      expect(account.reload).to be_support
    end

    it "is not offered to the support" do
      sign_in(support)

      get edit_support_user_path(account)

      expect(response.body).not_to include("user[support]")
    end
  end
end
