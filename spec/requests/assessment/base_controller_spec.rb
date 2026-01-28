require "rails_helper"

RSpec.describe("Assessment::BaseController", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }

  before do
    sign_in teacher
  end

  describe "feature flag check" do
    context "when assessment_grading feature is enabled" do
      before { Flipper.enable(:assessment_grading) }

      after { Flipper.disable(:assessment_grading) }

      it "allows access to assessment routes" do
        get assessment_assessments_path(lecture_id: lecture.id)
        expect(response).to have_http_status(:success)
      end
    end

    context "when assessment_grading feature is disabled" do
      before { Flipper.disable(:assessment_grading) }

      it "redirects to root path" do
        get assessment_assessments_path(lecture_id: lecture.id)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
