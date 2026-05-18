require "rails_helper"

RSpec.describe("StudentPerformance::Achievements", type: :request) do
  let(:lecture) { FactoryBot.create(:lecture, locale: I18n.default_locale) }
  let(:editor) { FactoryBot.create(:confirmed_user) }
  let(:student) { FactoryBot.create(:confirmed_user) }

  before do
    Flipper.enable(:student_performance)
    FactoryBot.create(:editable_user_join, user: editor, editable: lecture)
    editor.reload
    lecture.reload
  end

  after do
    Flipper.disable(:student_performance)
  end

  describe "GET /lectures/:lecture_id/performance/achievements" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get lecture_student_performance_achievements_path(lecture)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        get lecture_student_performance_achievements_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /lectures/:lecture_id/performance/achievements/new" do
    context "as an editor" do
      before { sign_in editor }

      it "returns turbo stream with the form" do
        get new_lecture_student_performance_achievement_path(lecture),
            as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      end

      it "redirects to index for HTML requests" do
        get new_lecture_student_performance_achievement_path(lecture)
        expect(response).to redirect_to(
          lecture_student_performance_achievements_path(lecture)
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        get new_lecture_student_performance_achievement_path(lecture),
            as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /lectures/:lecture_id/performance/achievements/:id" do
    let!(:achievement) do
      FactoryBot.create(:achievement, lecture: lecture)
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns turbo stream with the dashboard" do
        get lecture_student_performance_achievement_path(lecture, achievement),
            as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      end

      it "redirects to index for HTML requests" do
        get lecture_student_performance_achievement_path(lecture, achievement)
        expect(response).to redirect_to(
          lecture_student_performance_achievements_path(lecture)
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        get lecture_student_performance_achievement_path(lecture, achievement),
            as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /lectures/:lecture_id/performance/achievements" do
    let(:valid_params) do
      { achievement: { title: "Blackboard Presentation",
                       value_type: "boolean" } }
    end

    context "as an editor" do
      before { sign_in editor }

      it "creates an achievement" do
        expect do
          post(lecture_student_performance_achievements_path(lecture),
               params: valid_params)
        end.to change(Achievement, :count).by(1)
      end

      it "rejects invalid params" do
        post lecture_student_performance_achievements_path(lecture),
             params: { achievement: { title: "", value_type: "boolean" } }
        expect(response).to redirect_to(
          lecture_student_performance_achievements_path(lecture)
        )
        expect(flash[:alert]).to be_present
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        post lecture_student_performance_achievements_path(lecture),
             params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /lectures/:lecture_id/performance/achievements/:id" do
    let!(:achievement) do
      FactoryBot.create(:achievement, lecture: lecture)
    end

    context "as an editor" do
      before { sign_in editor }

      let!(:assessment) do
        achievement.ensure_assessment!(
          requires_points: false, requires_submission: false
        )
      end

      let!(:participation) do
        create(:assessment_participation,
               assessment: assessment,
               grade_text: "85.0")
      end

      it "updates the achievement" do
        patch lecture_student_performance_achievement_path(lecture, achievement),
              params: { achievement: { title: "Updated Title" } }
        expect(achievement.reload.title).to eq("Updated Title")
      end

      it "rejects invalid params" do
        patch lecture_student_performance_achievement_path(lecture, achievement),
              params: { achievement: { title: "" } }
        expect(response).to redirect_to(
          lecture_student_performance_achievements_path(lecture)
        )
        expect(flash[:alert]).to be_present
      end

      it "returns an unprocessable turbo response for blank threshold" do
        achievement.update!(value_type: :percentage, threshold: 80.0)

        patch lecture_student_performance_achievement_path(lecture, achievement),
              params: {
                achievement: {
                  title: achievement.title,
                  value_type: "percentage",
                  threshold: "",
                  description: achievement.description
                }
              },
              as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
        expect(response.body).to include(
          %(data-achievement-form-has-errors-value="true")
        )
        expect(response.body).to include(
          %(data-achievement-form-original-threshold-value="80.0")
        )
      end

      it "renders validation errors only through invalid-feedback" do
        patch lecture_student_performance_achievement_path(lecture, achievement),
              params: { achievement: { title: "" } },
              as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("invalid-feedback")
        expect(response.body).not_to include("text-danger small mt-1")
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        patch lecture_student_performance_achievement_path(lecture, achievement),
              params: { achievement: { title: "Hack" } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /lectures/:lecture_id/performance/achievements/:id" do
    let!(:achievement) do
      FactoryBot.create(:achievement, lecture: lecture)
    end

    context "as an editor" do
      before { sign_in editor }

      it "destroys the achievement" do
        expect do
          delete(lecture_student_performance_achievement_path(
                   lecture, achievement
                 ))
        end.to change(Achievement, :count).by(-1)
      end

      it "keeps the destroy error in turbo responses" do
        allow_any_instance_of(Achievement).to receive(:destroy) do |record|
          record.errors.add(:base, "Achievement is still in use")
          false
        end

        delete lecture_student_performance_achievement_path(
          lecture, achievement
        ), as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_content)
        assert_flash_error
        expect(response.body).to include("Achievement is still in use")
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        delete lecture_student_performance_achievement_path(
          lecture, achievement
        )
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "feature flag disabled" do
    before do
      Flipper.disable(:student_performance)
      sign_in editor
    end

    it "does not route to achievements index" do
      get lecture_student_performance_achievements_path(lecture)
      expect(response).to redirect_to(root_path)
    end
  end
end
