require "rails_helper"

RSpec.describe("Exams registration", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }

  before do
    Flipper.enable(:assessment_grading)
    sign_in teacher
  end

  after do
    Flipper.disable(:assessment_grading)
    Flipper.disable(:registration_campaigns)
  end

  describe "POST /exams" do
    let(:valid_attributes) do
      {
        title: "New Exam",
        lecture_id: lecture.id,
        date: 2.weeks.from_now.strftime("%Y-%m-%d %H:%M"),
        location: "Room 101",
        capacity: 50,
        description: "Final exam"
      }
    end

    before do
      Flipper.enable(:registration_campaigns)
    end

    it "auto-creates a registration campaign" do
      expect do
        post(exams_path,
             params: { exam: valid_attributes },
             as: :turbo_stream)
      end.to change(Registration::Campaign, :count).by(1)

      created_exam = Exam.order(created_at: :desc).first

      expect(created_exam.registration_campaign).to be_present
      expect(created_exam.registration_campaign).to be_draft
      expect(created_exam.registration_campaign).to be_first_come_first_served
    end

    it "uses registration_deadline when provided" do
      deadline = 1.week.from_now.beginning_of_hour
      attrs = valid_attributes.merge(
        registration_deadline: deadline.strftime("%Y-%m-%d %H:%M")
      )

      post(exams_path,
           params: { exam: attrs },
           as: :turbo_stream)

      created_exam = Exam.order(created_at: :desc).first

      expect(created_exam.registration_campaign.registration_deadline)
        .to be_within(1.minute).of(deadline)
    end

    it "does not create a campaign when skip_campaigns is true" do
      attrs = valid_attributes.merge(skip_campaigns: "1")

      expect do
        post(exams_path,
             params: { exam: attrs },
             as: :turbo_stream)
      end.not_to change(Registration::Campaign, :count)
    end
  end

  describe "GET /exams/:id" do
    before do
      Flipper.enable(:registration_campaigns)
    end

    it "renders the registration tab and inline policies in settings" do
      get exam_path(exam), as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.body).to include(
        "data-bs-target=\"#dashboard-exam-#{exam.id}-registration\""
      )
      expect(response.body).to include(I18n.t("registration.policy.index.title"))
      expect(response.body).to include(I18n.t("registration.campaign.actions.open"))
    end

    it "renders the deadline form disabled for a closed campaign" do
      exam.registration_campaign.update!(status: :closed)

      get exam_path(exam), params: { tab: "registration" }, as: :turbo_stream

      document = Nokogiri::HTML.fragment(response.body)
      deadline_input = document.at_css("#exam_registration_deadline")

      expect(response).to have_http_status(:success)
      expect(deadline_input).to be_present
      expect(deadline_input["disabled"]).to eq("disabled")
      expect(response.body).not_to include("exams--registration-settings")
    end
  end

  describe "POST /exams/:id/participants" do
    it "adds a participant by user id" do
      expect do
        post(participants_exam_path(exam),
             params: { user_id: student.id },
             as: :turbo_stream)
      end.to change { exam.reload.exam_roster_entries.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        I18n.t("assessment.registration_tab.participant_added",
               name: student.tutorial_name.presence || student.email)
      )
    end

    it "reactivates an excluded participant" do
      roster_entry = create(:exam_roster_entry,
                            exam: exam,
                            user: student,
                            excluded_at: Time.current)

      expect do
        post(participants_exam_path(exam),
             params: { user_id: student.id },
             as: :turbo_stream)
      end.not_to change(ExamRosterEntry, :count)

      expect(response).to have_http_status(:ok)
      expect(roster_entry.reload.excluded_at).to be_nil
    end

    it "rejects already active participants" do
      create(:exam_roster_entry, exam: exam, user: student)

      expect do
        post(participants_exam_path(exam),
             params: { user_id: student.id },
             as: :turbo_stream)
      end.not_to change(ExamRosterEntry, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        I18n.t("assessment.registration_tab.already_registered")
      )
    end
  end

  describe "PATCH /exams/:id" do
    before do
      Flipper.enable(:registration_campaigns)
    end

    it "reopens the campaign when saving a deadline fix for reopen" do
      campaign = exam.registration_campaign
      campaign.update!(status: :closed)
      deadline = 1.week.from_now.beginning_of_hour

      patch(exam_path(exam),
            params: {
              exam: {
                registration_deadline: deadline.strftime("%Y-%m-%d %H:%M")
              },
              tab: "registration",
              reopen_after_deadline_fix: "1"
            },
            as: :turbo_stream)

      campaign.reload

      expect(campaign).to be_open
      expect(campaign.registration_deadline).to be_within(1.minute).of(deadline)
      expect(response).to have_http_status(:ok)
    end

    it "does not change the deadline for a closed campaign without reopen mode" do
      campaign = exam.registration_campaign
      campaign.update!(status: :closed)
      original_deadline = campaign.registration_deadline

      patch(exam_path(exam),
            params: {
              exam: {
                registration_deadline: 1.week.from_now.beginning_of_hour.strftime(
                  "%Y-%m-%d %H:%M"
                )
              },
              tab: "registration"
            },
            as: :turbo_stream)

      campaign.reload

      expect(campaign.registration_deadline).to eq(original_deadline)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /exams/:id/participants/:user_id" do
    before do
      create(:exam_roster_entry, exam: exam, user: student)
    end

    it "removes a participant" do
      expect do
        delete(remove_participant_exam_path(exam, user_id: student.id),
               as: :turbo_stream)
      end.to change { exam.reload.exam_roster_entries.count }.by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        I18n.t("assessment.registration_tab.participant_removed",
               name: student.tutorial_name.presence || student.email)
      )
    end
  end
end
