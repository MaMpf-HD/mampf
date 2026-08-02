require "rails_helper"

RSpec.describe("Vignettes::InfoSlides", type: :request) do
  let(:student) { create(:confirmed_user) }
  let(:questionnaire) { create(:vignettes_questionnaire) }
  let(:editor) { questionnaire.lecture.teacher }
  let(:params) { { vignettes_info_slide: { title: "T", content: "C", icon_type: "eye" } } }

  describe "POST /questionnaires/:questionnaire_id/info_slides" do
    it "lets a lecture editor add an info slide" do
      sign_in editor
      expect do
        post(questionnaire_info_slides_path(questionnaire), params: params)
      end.to change(Vignettes::InfoSlide, :count).by(1)
    end

    it "does not let a student add an info slide" do
      sign_in student
      expect do
        post(questionnaire_info_slides_path(questionnaire), params: params)
      end.not_to change(Vignettes::InfoSlide, :count)
    end
  end

  describe "DELETE /questionnaires/:questionnaire_id/info_slides/:id" do
    let!(:info_slide) { create(:vignettes_info_slide, questionnaire: questionnaire) }

    it "lets a lecture editor delete an info slide" do
      sign_in editor
      expect do
        delete(questionnaire_info_slide_path(questionnaire, info_slide))
      end.to change(Vignettes::InfoSlide, :count).by(-1)
    end

    it "does not let a student delete an info slide" do
      sign_in student
      expect do
        delete(questionnaire_info_slide_path(questionnaire, info_slide))
      end.not_to change(Vignettes::InfoSlide, :count)
    end
  end
end
