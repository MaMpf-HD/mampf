require "rails_helper"

RSpec.describe("Vignettes::Questionnaires", type: :request) do
  let(:student) { create(:confirmed_user) }

  describe "POST /questionnaires" do
    let(:lecture) { create(:lecture, sort: "vignettes") }
    let(:params) { { title: "New questionnaire", lecture_id: lecture.id } }

    it "lets a lecture editor create a questionnaire" do
      sign_in lecture.teacher
      expect do
        post(questionnaires_path, params: params)
      end.to change(Vignettes::Questionnaire, :count).by(1)
    end

    it "does not let a student create a questionnaire" do
      sign_in student
      expect do
        post(questionnaires_path, params: params)
      end.not_to change(Vignettes::Questionnaire, :count)
    end
  end

  describe "GET /questionnaires/:id/export_statistics" do
    let(:questionnaire) { create(:vignettes_questionnaire) }

    it "lets a lecture editor export the answer statistics" do
      sign_in questionnaire.lecture.teacher
      get export_statistics_questionnaire_path(questionnaire)
      expect(response).to have_http_status(:ok)
    end

    it "does not let a student export the answer statistics" do
      sign_in student
      get export_statistics_questionnaire_path(questionnaire)
      expect(response).to redirect_to(lecture_questionnaires_path(questionnaire.lecture))
    end
  end
end
