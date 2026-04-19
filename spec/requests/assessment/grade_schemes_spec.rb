require "rails_helper"

RSpec.describe("Assessment::GradeSchemes", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }
  let(:assessment) { create(:assessment, :for_exam, assessable: exam, lecture: lecture) }

  before do
    Flipper.enable(:assessment_grading)
  end

  after do
    Flipper.disable(:assessment_grading)
  end

  let(:valid_config) do
    {
      "bands" => [
        { "min_points" => 54, "grade" => "1.0" },
        { "min_points" => 48, "grade" => "1.3" },
        { "min_points" => 42, "grade" => "1.7" },
        { "min_points" => 36, "grade" => "2.0" },
        { "min_points" => 33, "grade" => "2.3" },
        { "min_points" => 30, "grade" => "3.0" },
        { "min_points" => 27, "grade" => "3.7" },
        { "min_points" => 24, "grade" => "4.0" },
        { "min_points" => 0,  "grade" => "5.0" }
      ]
    }
  end

  describe "GET /assessment/assessments/:assessment_id/grade_schemes/new" do
    context "as a teacher" do
      before { sign_in teacher }

      it "renders turbo_stream with dashboard" do
        get new_assessment_assessment_grade_scheme_path(assessment),
            as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects (unauthorized)" do
        get new_assessment_assessment_grade_scheme_path(assessment),
            as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /assessment/assessments/:assessment_id/grade_schemes" do
    before { sign_in teacher }

    context "with valid parameters" do
      it "creates a grade scheme" do
        expect do
          post(assessment_assessment_grade_schemes_path(assessment),
               params: {
                 kind: "banded",
                 config_json: valid_config.to_json
               },
               as: :turbo_stream)
        end.to change(Assessment::GradeScheme, :count).by(1)
      end

      it "renders turbo_stream" do
        post assessment_assessment_grade_schemes_path(assessment),
             params: {
               kind: "banded",
               config_json: valid_config.to_json
             },
             as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end
    end

    context "with invalid parameters" do
      it "does not create a grade scheme" do
        expect do
          post(assessment_assessment_grade_schemes_path(assessment),
               params: {
                 kind: "banded",
                 config_json: {}.to_json
               },
               as: :turbo_stream)
        end.not_to change(Assessment::GradeScheme, :count)
      end

      it "renders unprocessable_content" do
        post assessment_assessment_grade_schemes_path(assessment),
             params: {
               kind: "banded",
               config_json: {}.to_json
             },
             as: :turbo_stream
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects (unauthorized)" do
        post assessment_assessment_grade_schemes_path(assessment),
             params: { kind: "banded", config_json: valid_config.to_json },
             as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /assessment/assessments/:assessment_id/grade_schemes/:id" do
    let!(:grade_scheme) { create(:assessment_grade_scheme, assessment: assessment) }

    before { sign_in teacher }

    context "with valid parameters" do
      let(:new_config) do
        valid_config.deep_dup.tap do |c|
          c["bands"].first["min_points"] = 55
        end
      end

      it "updates the grade scheme" do
        patch assessment_assessment_grade_scheme_path(assessment, grade_scheme),
              params: {
                config_json: new_config.to_json
              },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
        grade_scheme.reload
        expect(grade_scheme.config["bands"].first["min_points"]).to eq(55)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects (unauthorized)" do
        patch assessment_assessment_grade_scheme_path(assessment, grade_scheme),
              params: { config_json: valid_config.to_json },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /assessment/assessments/:assessment_id/grade_schemes/:id/preview" do
    let!(:grade_scheme) { create(:assessment_grade_scheme, assessment: assessment) }

    before { sign_in teacher }

    it "renders turbo_stream" do
      get preview_assessment_assessment_grade_scheme_path(assessment, grade_scheme),
          as: :turbo_stream
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
    end

    context "as a student" do
      before { sign_in student }

      it "redirects (unauthorized)" do
        get preview_assessment_assessment_grade_scheme_path(assessment, grade_scheme),
            as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /assessment/assessments/:assessment_id/grade_schemes/:id/apply" do
    let!(:grade_scheme) { create(:assessment_grade_scheme, assessment: assessment) }

    before { sign_in teacher }

    it "applies the grade scheme" do
      patch apply_assessment_assessment_grade_scheme_path(assessment, grade_scheme),
            as: :turbo_stream
      grade_scheme.reload
      expect(grade_scheme).to be_applied
    end

    it "redirects to dashboard" do
      patch apply_assessment_assessment_grade_scheme_path(assessment, grade_scheme)
      expect(response).to redirect_to(exam_path(exam, tab: "grade_scheme"))
    end

    context "as a student" do
      before { sign_in student }

      it "redirects (unauthorized)" do
        patch apply_assessment_assessment_grade_scheme_path(assessment, grade_scheme),
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "when assessment does not exist" do
    before { sign_in teacher }

    it "redirects to root" do
      get new_assessment_assessment_grade_scheme_path(99_999),
          as: :turbo_stream
      expect(response).to redirect_to(root_path)
    end
  end

  describe "when grade scheme does not exist" do
    before { sign_in teacher }

    it "redirects to dashboard" do
      get preview_assessment_assessment_grade_scheme_path(assessment, 99_999),
          as: :turbo_stream
      expect(response).to redirect_to(exam_path(exam, tab: "grade_scheme"))
    end

    it "redirects when id belongs to a different assessment" do
      other_exam = create(:exam, lecture: lecture)
      other_assessment = other_exam.reload.assessment
      other_scheme = create(:assessment_grade_scheme, assessment: other_assessment)
      get preview_assessment_assessment_grade_scheme_path(assessment, other_scheme),
          as: :turbo_stream
      expect(response).to redirect_to(exam_path(exam, tab: "grade_scheme"))
    end

    it "redirects when scheme exists but is inactive" do
      scheme = create(:assessment_grade_scheme, assessment: assessment)
      scheme.update!(active: false)
      get preview_assessment_assessment_grade_scheme_path(assessment, scheme),
          as: :turbo_stream
      expect(response).to redirect_to(exam_path(exam, tab: "grade_scheme"))
    end
  end
end
