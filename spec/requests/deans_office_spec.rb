require "rails_helper"

RSpec.describe("Dean's office", type: :request) do
  let(:office) { create(:confirmed_user_en, deans_office: true) }
  let(:term) { create(:term, :active) }
  let(:lecture) { create(:lecture, term: term) }

  describe "who gets in" do
    it "lets the dean's office and admins in" do
      [office, create(:confirmed_user_en, admin: true)].each do |user|
        sign_in(user)
        get deans_office_path

        expect(response).to have_http_status(:ok)
      end
    end

    it "keeps teachers and students out" do
      [lecture.teacher, create(:confirmed_user_en)].each do |user|
        sign_in(user)
        get deans_office_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "the term's lectures" do
    before { sign_in(office) }

    it "lists the active term's lectures with how full their groups are" do
      tutorial = create(:tutorial, lecture: lecture, title: "Tuesday group", capacity: 10)
      3.times { create(:tutorial_membership, tutorial: tutorial) }
      other = create(:lecture, term: create(:term))

      get deans_office_path

      expect(response.body).to include(CGI.escapeHTML(lecture.title_no_term), "Tuesday group",
                                       "3 / 10")
      expect(response.body).not_to include(CGI.escapeHTML(other.title_no_term))
    end

    it "counts the lecture's members and only the active exam roster" do
      2.times { create(:lecture_membership, lecture: lecture) }
      exam = create(:exam, lecture: lecture, capacity: 1)
      create_list(:exam_roster_entry, 2, exam: exam)
      create(:exam_roster_entry, exam: exam, excluded_at: 1.day.ago)

      get deans_office_path

      doc = Nokogiri::HTML(response.body)
      lecture_row = doc.at_css("tbody[data-deans-office-target='lecture'] > tr")
      row = doc.css("tr").find { |tr| tr.text.include?(exam.title) }
      cells = lecture_row.css("td").map { |td| td.text.strip }
      expect(cells.values_at(2, 3, 5)).to eq(["1", "1", "2"])
      expect(row.text).to include("2 / 1")
      expect(row.at_css(".progress-bar")[:class]).to include("bg-danger")
    end

    # 35 lectures a term: one line each, the filter finds one by title or teacher.
    it "gives each lecture one line and its groups behind a button" do
      create(:tutorial, lecture: lecture, title: "Tuesday group")

      get deans_office_path

      doc = Nokogiri::HTML(response.body)
      button = doc.at_css("button[data-action='deans-office#toggle']")
      groups = doc.at_css("##{button["aria-controls"]}")
      expect(button["aria-expanded"]).to eq("false")
      expect(groups["hidden"]).not_to be_nil
      expect(groups.text).to include("Tuesday group")
      expect(doc.at_css("tbody[data-deans-office-target='lecture']")["data-filter-text"])
        .to include(lecture.title_no_term.downcase, lecture.teacher.tutorial_name.downcase)
    end

    # The rosters stay empty until the allocation; the registrations say who
    # is coming, counted as the lecturer's campaign card counts them.
    it "counts the registrations of the running campaigns" do
      monday = create(:tutorial, lecture: lecture, title: "Monday group", capacity: 12)
      reading = create(:cohort, context: lecture, title: "Reading group")
      first_come = create(:registration_campaign, :first_come_first_served,
                          campaignable: lecture)
      monday_item = create(:registration_item, registration_campaign: first_come,
                                               registerable: monday)
      preferences = create(:registration_campaign, :preference_based, campaignable: lecture)
      reading_item = create(:registration_item, registration_campaign: preferences,
                                                registerable: reading)
      create(:registration_item, registration_campaign: preferences,
                                 registerable: create(:cohort, context: lecture))
      [first_come, preferences].each { |campaign| campaign.update!(status: :open) }
      people = create_list(:confirmed_user, 3)
      people.first(2).each do |person|
        create(:registration_user_registration, :confirmed, user: person,
                                                            registration_campaign: first_come,
                                                            registration_item: monday_item)
      end
      create(:registration_user_registration, user: people.first, preference_rank: 1,
                                              registration_campaign: preferences,
                                              registration_item: reading_item)
      create(:registration_user_registration, user: people.last, preference_rank: 2,
                                              registration_campaign: preferences,
                                              registration_item: reading_item)

      get deans_office_path

      doc = Nokogiri::HTML(response.body)
      lecture_cells = doc.at_css("tbody[data-deans-office-target='lecture'] > tr")
                         .css("td").map { |td| td.text.strip }
      monday_row = doc.css("tr").find { |tr| tr.at_css("th")&.text&.strip == "Monday group" }
      reading_row = doc.css("tr").find { |tr| tr.at_css("th")&.text&.strip == "Reading group" }
      expect(lecture_cells[4]).to eq("3")
      expect(monday_row.css("td").map { |td| td.text.strip }.values_at(2, 3))
        .to eq(["12", "2"])
      expect(reading_row.text).to include("1 (first choice)")
    end

    # Without knowing how people get into a group the numbers cannot be read.
    it "says for each group how people get into it" do
      states = {
        "Open group" => [:first_come_first_served, :open],
        "Waiting group" => [:preference_based, :closed],
        "Draft group" => [:first_come_first_served, :draft]
      }
      states.each do |title, (mode, status)|
        tutorial = create(:tutorial, lecture: lecture, title: title)
        campaign = create(:registration_campaign, mode, campaignable: lecture)
        create(:registration_item, registration_campaign: campaign, registerable: tutorial)
        campaign.update!(status: status, registration_deadline: 1.week.from_now) if status == :open
        campaign.update!(status: status, registration_deadline: 1.day.ago) if status == :closed
      end
      create(:tutorial, lecture: lecture, title: "Unassigned group")
      create(:tutorial, lecture: lecture, title: "Joined group", skip_campaigns: true,
                        self_materialization_mode: :add_only)
      create(:tutorial, lecture: lecture, title: "Teacher's group", skip_campaigns: true)

      get deans_office_path

      rows = Nokogiri::HTML(response.body).css("tr").to_h do |tr|
        [tr.at_css("th")&.text&.strip, tr.text.squish]
      end
      expect(rows["Open group"]).to include("open until", "first come, first served")
      expect(rows["Waiting group"]).to include("closed, allocation pending")
      expect(rows["Draft group"]).to include("registration not open yet")
      expect(rows["Unassigned group"]).to include("waits for a registration")
      expect(rows["Joined group"]).to include("students join themselves")
      expect(rows["Teacher's group"]).to include("only through the teacher")
    end

    it "shows another term's lectures when it is picked" do
      other = create(:lecture, term: create(:term))

      get deans_office_path(term: other.term.dashboard_param)

      expect(response.body).to include(CGI.escapeHTML(other.title_no_term))
    end
  end

  describe "the admin's switch" do
    let(:account) { create(:confirmed_user) }

    it "lets an admin give somebody the dean's office role" do
      sign_in(create(:confirmed_user, admin: true))

      patch support_user_path(account), params: { user: { deans_office: "1" } }

      expect(account.reload).to be_deans_office
    end

    it "does not let a teacher or the support give the dean's office role" do
      teacher = create(:confirmed_user)
      create(:lecture, teacher: teacher)
      [teacher, create(:confirmed_user, support: true)].each do |user|
        sign_in(user)

        patch support_user_path(account), params: { user: { name: "Ada", deans_office: "1" } }
        patch support_user_path(user), params: { user: { name: "Ada", deans_office: "1" } }
      end

      expect(User.where(deans_office: true)).to be_empty
    end
  end
end
