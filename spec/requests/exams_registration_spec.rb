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
