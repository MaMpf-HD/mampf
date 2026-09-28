require "rails_helper"

RSpec.describe("Records office", type: :request) do
  let(:office) { create(:confirmed_user_en, records_office: true) }
  let(:term) { create(:term, :active) }
  let(:lecture) { create(:lecture, term: term) }

  def person(last_name, first_name, matriculation_number = nil)
    create(:confirmed_user, last_name: last_name, first_name: first_name,
                            matriculation_number: matriculation_number)
  end

  def csv_rows
    expect(response.body).to start_with("\uFEFF")
    CSV.parse(response.body.delete_prefix("\uFEFF"), col_sep: ";", headers: true)
  end

  describe "who gets in" do
    it "lets the records office and admins in" do
      [office, create(:confirmed_user_en, admin: true)].each do |user|
        sign_in(user)
        get records_office_path

        expect(response).to have_http_status(:ok)
      end
    end

    it "keeps teachers and students out, downloads included" do
      teacher = lecture.teacher
      tutorial = create(:tutorial, lecture: lecture)
      [teacher, create(:confirmed_user_en)].each do |user|
        sign_in(user)
        get records_office_path
        expect(response).to redirect_to(root_path)

        get records_office_emails_path("tutorial", tutorial)
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

      get records_office_path

      expect(response.body).to include(CGI.escapeHTML(lecture.title_no_term), "Tuesday group",
                                       "3 / 10")
      expect(response.body).not_to include(CGI.escapeHTML(other.title_no_term))
    end

    it "shows another term's lectures when it is picked" do
      other = create(:lecture, term: create(:term))

      get records_office_path(term_id: other.term_id)

      expect(response.body).to include(CGI.escapeHTML(other.title_no_term))
    end

    it "offers the grades only once some were published" do
      exam = create(:exam, lecture: lecture)
      get records_office_path
      expect(response.body).not_to include(records_office_grades_path(lecture))

      exam.assessment.update!(results_published_at: 1.hour.ago)
      get records_office_path
      expect(response.body).to include(records_office_grades_path(lecture))
    end
  end

  describe "the downloads" do
    before { sign_in(office) }

    it "lists a group's members by last name, for German Excel" do
      tutorial = create(:tutorial, lecture: lecture)
      [person("Zuse", "Konrad"), person("Noether", "Emmy", "1234567")].each do |user|
        create(:tutorial_membership, tutorial: tutorial, user: user)
      end
      create(:tutorial_membership, tutorial: create(:tutorial, lecture: lecture))

      get records_office_emails_path("tutorial", tutorial)

      rows = csv_rows
      expect(rows.headers).to eq(["Last name", "First name", "Matriculation number", "Email"])
      expect(rows.map { |row| row["Last name"] }).to eq(["Noether", "Zuse"])
      expect(rows.first["Matriculation number"]).to eq("1234567")
    end

    it "gives the published grades of exams and talks, and nothing still being graded" do
      seminar = create(:lecture, term: term, sort: "seminar")
      published = create(:exam, lecture: seminar, title: "Final exam")
      published.assessment.update!(results_published_at: 1.hour.ago)
      noether = person("Noether", "Emmy")
      create(:assessment_participation, :reviewed, assessment: published.assessment,
                                                   user: noether, grade_numeric: 2.3)
      create(:assessment_participation, :absent, assessment: published.assessment,
                                                 user: person("Zuse", "Konrad"))
      hidden = create(:exam, lecture: seminar, title: "Resit")
      create(:assessment_participation, :reviewed, assessment: hidden.assessment,
                                                   user: noether, grade_numeric: 1.0)

      talk = create(:talk, lecture: seminar, title: "Primes")
      talk.assessment.update!(results_published_at: 1.hour.ago)
      create(:assessment_participation, :reviewed, assessment: talk.assessment,
                                                   user: noether, grade_numeric: 1.0)

      get records_office_grades_path(seminar)

      expect(csv_rows.map { |row| row.fields("Last name", "Kind", "Title", "Grade", "Status") })
        .to eq([["Noether", "Exam", "Final exam", "2,3", nil],
                ["Zuse", "Exam", "Final exam", nil, "absent"],
                ["Noether", "Talk", talk.to_label, "1,0", nil]])
    end

    it "gives exactly the results the students were shown, and no sheets" do
      exam = create(:exam, lecture: lecture, title: "Final exam")
      exam.assessment.update!(results_published_at: 1.hour.ago)
      create(:assessment_participation, :reviewed, assessment: exam.assessment,
                                                   user: person("Noether", "Emmy"))
      create(:assessment_participation, assessment: exam.assessment,
                                        user: person("Zuse", "Konrad"), grade_text: "")
      assignment = create(:assignment, :expired, lecture: lecture)
      assignment.assessment.update!(results_published_at: 1.hour.ago)
      create(:assessment_participation, :reviewed, assessment: assignment.assessment,
                                                   user: person("Gauss", "Carl"))

      get records_office_grades_path(lecture)

      expect(csv_rows.map { |row| row.fields("Last name", "Title", "Grade") })
        .to eq([["Noether", "Final exam", nil]])
    end

    it "gives the exam admissions with what they rest on" do
      noether = person("Noether", "Emmy")
      create(:student_performance_record, lecture: lecture, user: noether,
                                          points_total_materialized: 42.5,
                                          points_max_materialized: 60,
                                          percentage_materialized: 70.83)
      create(:student_performance_certification, :passed, :manual,
             lecture: lecture, user: noether, note: "Certificate from the doctor")

      get records_office_admissions_path(lecture)

      rows = csv_rows
      expect(rows.first.fields("Last name", "Points", "Maximum", "Percentage", "Decision", "Note"))
        .to eq(["Noether", "42,5", "60", "70,83", "eligible", "Certificate from the doctor"])
    end
  end

  describe "the admin's switch" do
    let(:account) { create(:confirmed_user) }

    it "lets an admin make somebody the records office" do
      sign_in(create(:confirmed_user, admin: true))

      patch user_path(account), params: { user: { records_office: "1" } }, xhr: true

      expect(account.reload).to be_records_office
    end

    it "does not let a teacher make themselves the records office" do
      create(:lecture, teacher: account)
      sign_in(account)

      patch user_path(account), params: { user: { name: "Ada", records_office: "1" } }, xhr: true

      expect(account.reload).not_to be_records_office
    end
  end
end
