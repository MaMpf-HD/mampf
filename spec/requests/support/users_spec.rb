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

    it "keeps teachers, editors and students out, corrections included" do
      teacher = create(:confirmed_user_en)
      create(:lecture, teacher: teacher)
      editor = create(:confirmed_user_en)
      create(:lecture).editors << editor
      [teacher, editor, create(:confirmed_user_en)].each do |user|
        sign_in(user)

        get support_users_path
        expect(response).to redirect_to(root_path)

        patch support_user_path(student), params: { user: { last_name: "Lasker" } }
        expect(student.reload.last_name).to eq("Noether")
      end
    end

    # Otherwise a redirect for an existing id and a 404 for a missing one would
    # tell anybody which ids exist.
    it "answers outsiders the same whether the account exists or not" do
      sign_in(create(:confirmed_user_en))

      get edit_support_user_path(student)
      expect(response).to redirect_to(root_path)

      get edit_support_user_path(id: User.maximum(:id) + 1)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "the support's limits" do
    before { sign_in(support) }

    it "cannot make themselves an admin" do
      patch support_user_path(support),
            params: { user: { last_name: "Test", admin: "1", support: "0" } }

      expect(support.reload).to have_attributes(last_name: "Test", admin: false, support: true)
    end

    it "changes neither the password nor the tokens of an account" do
      patch support_user_path(student),
            params: { user: { last_name: "Test", password: "AnOwnedPassword123!",
                              encrypted_password: "x", reset_password_token: "owned",
                              confirmation_token: "owned", unconfirmed_email: "o@example.org" } }

      expect(student.reload).to have_attributes(last_name: "Test", reset_password_token: nil,
                                                unconfirmed_email: nil)
      expect(student.valid_password?("AnOwnedPassword123!")).to be(false)
    end

    it "keeps away from an admin's account in every action" do
      admin = create(:confirmed_user, admin: true, locked_at: 1.minute.ago, failed_attempts: 5)
      ActionMailer::Base.deliveries.clear

      get edit_support_user_path(admin)
      expect(response).to redirect_to(root_path)
      patch unlock_support_user_path(admin)
      post confirmation_support_user_path(admin)
      delete support_user_path(admin)

      expect(admin.reload).to have_attributes(failed_attempts: 5)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "does not break on a search address that is not a search" do
      get support_users_path, params: { search: "abc" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "the search" do
    before { sign_in(support) }

    it "lists nobody before anything is asked for" do
      get support_users_path

      expect(response.body).not_to include("emmy@example.org")
    end

    # The request line is logged with its query string, apart from the
    # parameters Rails logs separately.
    it "keeps what was searched for out of the logged path and parameters" do
      env = Rack::MockRequest.env_for(support_users_path(search: { fulltext: "Noether" }))
      env["action_dispatch.parameter_filter"] = Rails.application.config.filter_parameters
      request = ActionDispatch::Request.new(env)

      expect(request.filtered_path).not_to include("Noether")
      expect(request.filtered_parameters.to_s).not_to include("Noether")
    end

    it "puts the person first by matriculation number, last name or address" do
      create(:confirmed_user, last_name: "Hilbert", email: "david@example.org")

      ["1234567", "Noether", "emmy@example"].each do |query|
        search(fulltext: query)

        first_row = Nokogiri::HTML(response.body).at_css("#support-user-results tbody tr")
        expect(first_row.text).to include("emmy@example.org")
      end
    end

    # Every uni address ends in ".de"; the similarity search would find them all.
    it "counts only the beginnings of words below three characters" do
      create(:confirmed_user, first_name: "Li", last_name: "Wei", email: "wei@uni.de")
      create(:confirmed_user, last_name: "Hilbert", email: "david@uni.de")

      search(fulltext: "de")
      expect(response.body).not_to include("wei@uni.de", "david@uni.de")

      search(fulltext: "Li")
      expect(response.body).to include("wei@uni.de")
      expect(response.body).not_to include("david@uni.de")
    end

    it "asks for a second character instead of listing" do
      search(fulltext: "N")

      expect(response.body).to include("Type at least two characters.")
      expect(response.body).not_to include("emmy@example.org")
    end

    it "marks admins and the support in the hits" do
      create(:confirmed_user, last_name: "Noether", email: "admin@example.org", admin: true)

      search(fulltext: "Noether")

      rows = Nokogiri::HTML(response.body).css("#support-user-results tbody tr")
      admin_row = rows.find { |row| row.text.include?("admin@example.org") }
      expect(admin_row.text).to include(I18n.t("basics.administrator_short"))
    end

    # The dropdown offers what students pick; courses have their own programs.
    it "shows a chosen program again, ticked off and offered" do
      program = create(:program, degree: :msc)

      get support_users_path, params: { search: { all_programs: "0", program_ids: [program.id] } }

      doc = Nokogiri::HTML(response.body)
      all = doc.at_css("input[type=checkbox][name='search[all_programs]']")
      select = doc.at_css("select[name='search[program_ids][]']")
      expect(all["checked"]).to be_nil
      expect(select["disabled"]).to be_nil
      expect(select.css("option[selected]").pluck("value")).to eq([program.id.to_s])
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

    # Whoever types a new address gets its confirmation link: the support could
    # move any account to themselves and reset its password.
    it "leaves the address alone and sends nothing" do
      ActionMailer::Base.deliveries.clear

      patch support_user_path(student),
            params: { user: { last_name: "Lasker", email: "support@example.org" } }

      expect(student.reload).to have_attributes(last_name: "Lasker", email: "emmy@example.org",
                                                unconfirmed_email: nil)
      expect(ActionMailer::Base.deliveries).to be_empty
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

    # A failed sign-in short of the lock is reset by the next successful one;
    # "Unlock" beside an account that is not locked only confuses.
    it "offers unlocking to a locked account only" do
      student.update_columns(failed_attempts: 1) # rubocop:disable Rails/SkipsModelValidations
      get edit_support_user_path(student)
      expect(response.body).to include("no (1 failed sign-in in a row)")
      expect(response.body).not_to include(unlock_support_user_path(student))

      student.update_columns(locked_at: 5.minutes.ago, failed_attempts: 5) # rubocop:disable Rails/SkipsModelValidations
      get edit_support_user_path(student)
      expect(response.body).to include(unlock_support_user_path(student))
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

    it "says so, and sends nothing, when nothing waits for confirmation" do
      ActionMailer::Base.deliveries.clear

      post confirmation_support_user_path(student)
      follow_redirect!

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(response.body).to include("nothing left to confirm")
    end

    # Devise keeps the sign-in before the latest in last_sign_in_at.
    it "shows the latest sign-in" do
      student.update_columns(last_sign_in_at: Time.zone.local(2026, 9, 1, 10), # rubocop:disable Rails/SkipsModelValidations
                             current_sign_in_at: Time.zone.local(2026, 9, 20, 10))

      get edit_support_user_path(student)

      status = Nokogiri::HTML(response.body).at_css("[data-testid='support-account-status']").text
      expect(status).to include(I18n.l(Time.zone.local(2026, 9, 20, 10), format: :short))
    end

    it "offers the confirmation mail only while something waits for confirmation" do
      get edit_support_user_path(student)

      expect(response.body).not_to include("Send the confirmation mail again")
    end
  end

  describe "what only admins do" do
    let(:account) { create(:confirmed_user) }
    let(:admin) { create(:confirmed_user_en, admin: true) }

    it "lets an admin make somebody the support or an admin" do
      sign_in(admin)

      patch support_user_path(account), params: { user: { support: "1", admin: "1" } }

      expect(account.reload).to have_attributes(support: true, admin: true)
    end

    # Otherwise the last admin could lock everybody out.
    it "keeps an admin from taking their own admin rights" do
      sign_in(admin)

      patch support_user_path(admin), params: { user: { admin: "0" } }

      expect(admin.reload.admin).to be(true)
    end

    it "offers neither switch to the support" do
      sign_in(support)

      get edit_support_user_path(account)

      expect(response.body).not_to include("user[support]", "user[admin]")
    end

    it "lets an admin delete an account" do
      sign_in(admin)

      delete support_user_path(account)

      expect(User.exists?(account.id)).to be(false)
      expect(response).to redirect_to(support_users_path)
    end

    it "takes the account's exam registrations along" do
      entry = create(:exam_roster_entry, user: account)
      sign_in(admin)

      delete support_user_path(account)

      expect(User.exists?(account.id)).to be(false)
      expect(ExamRosterEntry.exists?(entry.id)).to be(false)
    end

    it "keeps the accounts of editors, admins and their own" do
      editor = create(:confirmed_user)
      create(:lecture).editors << editor
      other_admin = create(:confirmed_user, admin: true)
      sign_in(admin)

      [editor, other_admin, admin].each { |person| delete support_user_path(person) }

      expect(User.where(id: [editor, other_admin, admin].map(&:id)).count).to eq(3)
    end

    it "lets an admin delete a support account" do
      sign_in(admin)

      delete support_user_path(support)

      expect(User.exists?(support.id)).to be(false)
    end

    it "keeps the accounts of teachers, and the support's hands off deleting" do
      teacher = create(:confirmed_user)
      create(:lecture, teacher: teacher)
      sign_in(admin)
      delete support_user_path(teacher)

      sign_in(support)
      delete support_user_path(account)

      expect(User.exists?(teacher.id)).to be(true)
      expect(User.exists?(account.id)).to be(true)
    end
  end
end
