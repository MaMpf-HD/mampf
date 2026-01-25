require "rails_helper"

RSpec.describe("Assessment::Assessments", type: :request) do
  before do
    Flipper.enable(:assessment_grading)
  end

  after do
    Flipper.disable(:assessment_grading)
  end

  let(:teacher) { create(:confirmed_user) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher, editors: [editor]) }

  describe "GET /assessment/assessments" do
    context "with lecture_id parameter" do
      context "as a teacher" do
        before { sign_in teacher }

        it "returns http success" do
          get assessment_assessments_path(lecture_id: lecture.id)
          expect(response).to have_http_status(:success)
        end

        it "displays assessments" do
          create(:valid_assignment, lecture: lecture, title: "Test Assignment")
          get assessment_assessments_path(lecture_id: lecture.id)
          expect(response.body).to include("Test Assignment")
        end

        it "separates assessments with and without assessment records" do
          create(:valid_assignment, lecture: lecture, title: "With Assessment")
          assignment2 = create(:valid_assignment, lecture: lecture, title: "Without Assessment")
          assignment2.assessment&.destroy

          get assessment_assessments_path(lecture_id: lecture.id)
          expect(response.body).to include("With Assessment")
          expect(response.body).to include("Without Assessment")
        end

        context "with a seminar" do
          let(:seminar) { create(:seminar, teacher: teacher, editors: [editor]) }

          it "displays talks instead of assignments" do
            create(:talk, lecture: seminar, title: "Test Talk")
            get assessment_assessments_path(lecture_id: seminar.id)
            expect(response.body).to include("Test Talk")
          end
        end
      end

      context "as an editor" do
        before { sign_in editor }

        it "returns http success" do
          get assessment_assessments_path(lecture_id: lecture.id)
          expect(response).to have_http_status(:success)
        end
      end

      context "as a student" do
        before { sign_in student }

        it "redirects to root (unauthorized)" do
          get assessment_assessments_path(lecture_id: lecture.id)
          expect(response).to redirect_to(root_path)
        end
      end

      context "when lecture does not exist" do
        before { sign_in teacher }

        it "redirects to root" do
          get assessment_assessments_path(lecture_id: 99_999)
          expect(response).to redirect_to(root_path)
        end
      end
    end

    context "when feature flag is disabled" do
      before do
        Flipper.disable(:assessment_grading)
        sign_in teacher
      end

      it "redirects to root (route not found)" do
        get assessment_assessments_path(lecture_id: lecture.id)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /assessment/assessments/:id" do
    let!(:assignment) { create(:valid_assignment, lecture: lecture, title: "Test Assignment") }
    let!(:assessment) { assignment.assessment }

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get assessment_assessment_path(assessment.id),
            params: { assessable_type: "Assignment", assessable_id: assignment.id }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when assessable does not exist" do
      before { sign_in teacher }

      it "redirects when assessable not found" do
        get assessment_assessment_path(assessment.id),
            params: { assessable_type: "Assignment", assessable_id: 99_999 }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when assessable has no assessment" do
      let(:assignment_no_assessment) { create(:valid_assignment, lecture: lecture) }

      before do
        sign_in teacher
        assignment_no_assessment.assessment&.destroy
      end

      it "redirects with alert" do
        get assessment_assessment_path(999),
            params: { assessable_type: "Assignment", assessable_id: assignment_no_assessment.id }
        expect(response).to redirect_to(assessment_assessments_path(lecture_id: lecture.id))
      end
    end
  end

  describe "locale handling" do
    let(:german_lecture) { create(:lecture, teacher: teacher, locale: "de") }

    context "as a teacher" do
      before { sign_in teacher }

      it "uses lecture locale for index" do
        get assessment_assessments_path(lecture_id: german_lecture.id)
        expect(I18n.locale).to eq(:de)
      end
    end
  end

  describe "authorization" do
    context "when user is not signed in" do
      it "redirects index to sign in page" do
        get assessment_assessments_path(lecture_id: lecture.id)
        expect(response).to have_http_status(:redirect)
      end

      it "redirects show to sign in page" do
        assignment = create(:valid_assignment, lecture: lecture)
        assessment = assignment.assessment
        get assessment_assessment_path(assessment.id),
            params: { assessable_type: "Assignment", assessable_id: assignment.id }
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when user cannot edit lecture" do
      let(:other_user) { create(:confirmed_user) }

      before { sign_in other_user }

      it "redirects index to root" do
        get assessment_assessments_path(lecture_id: lecture.id)
        expect(response).to redirect_to(root_path)
      end

      it "redirects show to root" do
        assignment = create(:valid_assignment, lecture: lecture)
        assessment = assignment.assessment
        get assessment_assessment_path(assessment.id),
            params: { assessable_type: "Assignment", assessable_id: assignment.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "data loading" do
    before { sign_in teacher }

    context "for index action" do
      it "loads assignments for regular lectures" do
        create(:valid_assignment, lecture: lecture, title: "Assignment 1")
        create(:valid_assignment, lecture: lecture, title: "Assignment 2")

        get assessment_assessments_path(lecture_id: lecture.id)

        expect(response.body).to include("Assignment 1")
        expect(response.body).to include("Assignment 2")
      end

      it "orders assignments by created_at desc" do
        create(:valid_assignment, lecture: lecture, title: "First",
                                  created_at: 2.days.ago)
        create(:valid_assignment, lecture: lecture, title: "Second",
                                  created_at: 1.day.ago)
        create(:valid_assignment, lecture: lecture, title: "Third",
                                  created_at: Time.zone.now)

        get assessment_assessments_path(lecture_id: lecture.id)

        body = response.body
        third_pos = body.index("Third")
        second_pos = body.index("Second")
        first_pos = body.index("First")

        expect(third_pos).to be < second_pos
        expect(second_pos).to be < first_pos
      end

      it "separates assessables with and without assessments" do
        create(:valid_assignment, lecture: lecture, title: "With Assessment")
        assignment_without = create(:valid_assignment, lecture: lecture,
                                                       title: "Without Assessment")
        assignment_without.assessment&.destroy

        get assessment_assessments_path(lecture_id: lecture.id)

        expect(response.body).to include("With Assessment")
        expect(response.body).to include("Without Assessment")
      end
    end
  end

  describe "edge cases" do
    before { sign_in teacher }

    context "when lecture has no assignments" do
      it "renders empty state" do
        get assessment_assessments_path(lecture_id: lecture.id)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
