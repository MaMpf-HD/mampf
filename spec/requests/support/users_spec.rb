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

    it "saves the corrected fields and keeps who changed what" do
      patch support_user_path(student),
            params: { user: { last_name: "Noether-Lasker", matriculation_number: "7654321" } }

      expect(response).to redirect_to(edit_support_user_path(student))
      expect(student.reload).to have_attributes(last_name: "Noether-Lasker",
                                                matriculation_number: "7654321")
      expect(student.personal_data_changes.pluck(:field, :old_value, :new_value, :editor_id))
        .to contain_exactly(["last_name", "Noether", "Noether-Lasker", support.id],
                            ["matriculation_number", "1234567", "7654321", support.id])
    end

    it "touches nothing but the locked personal data" do
      patch support_user_path(student),
            params: { user: { last_name: "Lasker", email: "evil@example.org", admin: "1" } }

      expect(student.reload).to have_attributes(last_name: "Lasker", email: "emmy@example.org")
      expect(student.admin).to be_falsey
    end

    it "refuses a matriculation number somebody else has, and records nothing" do
      create(:confirmed_user, matriculation_number: "7654321")

      patch support_user_path(student), params: { user: { matriculation_number: "7654321" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(student.reload.matriculation_number).to eq("1234567")
      expect(student.personal_data_changes).to be_empty
    end

    it "says so when nothing has changed, and records nothing" do
      patch support_user_path(student), params: { user: { last_name: "Noether" } }
      follow_redirect!

      expect(response.body).to include("Nothing has changed.")
      expect(response.body).not_to include("The personal data has been corrected.")
      expect(student.personal_data_changes).to be_empty
    end

    it "shows the corrections so far" do
      patch support_user_path(student), params: { user: { first_name: "Amalie" } }
      follow_redirect!

      expect(response.body).to include("Amalie", "Emmy", support.email)
    end
  end

  describe "the admin's switch" do
    it "lets an admin make somebody the support" do
      account = create(:confirmed_user)
      sign_in(create(:confirmed_user, admin: true))

      patch user_path(account), params: { user: { support: "1" } }, xhr: true

      expect(account.reload).to be_support
    end
  end
end
