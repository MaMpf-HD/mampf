require "rails_helper"

RSpec.describe("Assessment::Assessments", type: :request) do
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
            talk = create(:talk, lecture: seminar, title: "Test Talk")
            create(:speaker_talk_join, talk: talk)
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
  end

  describe "GET /assessment/assessments/:id" do
    let!(:assignment) { create(:valid_assignment, lecture: lecture, title: "Test Assignment") }
    let!(:assessment) { assignment.assessment }

    context "as a teacher" do
      before { sign_in teacher }

      it "renders turbo_stream" do
        get assessment_assessment_path(assessment.id),
            params: { assessable_type: "Assignment", assessable_id: assignment.id },
            as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include("assessments_container")
      end

      it "answers a frame request with the dashboard itself" do
        get assessment_assessment_path(assessment.id),
            params: { assessable_type: "Assignment", assessable_id: assignment.id },
            headers: { "Turbo-Frame" => "assessment-assessments-frame" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("assessment-assessments-frame")
        expect(response.body).to include("Test Assignment")
      end

      it "renders the points tab when a non-submitter has been marked as participated" do
        tutorial = create(:tutorial, lecture: lecture)
        student = create(:confirmed_user)
        create(:tutorial_membership, tutorial: tutorial, user: student)
        assignment.assessment.tasks.create!(max_points: 10, position: 1)
        Assessment::Participation.create!(assessment: assignment.assessment,
                                          user: student, tutorial: tutorial)

        get assessment_assessment_path(assessment.id),
            params: { assessable_type: "Assignment", assessable_id: assignment.id,
                      tab: "points" },
            headers: { "Turbo-Frame" => "assessment-assessments-frame" }

        expect(response).to have_http_status(:success)
      end

      it "sends someone who opens the bare link to the lecture's assessment tab" do
        get assessment_assessment_path(assessment.id),
            params: { assessable_type: "Assignment", assessable_id: assignment.id,
                      tab: "tasks" }

        expect(response).to redirect_to(
          edit_lecture_path(lecture, tab: "assessments",
                                     assessment_id: assessment.id,
                                     assessable_type: "Assignment",
                                     assessable_id: assignment.id,
                                     assessment_tab: "tasks")
        )
      end
    end

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
        get assessment_assessment_path(assignment_no_assessment.id),
            params: { assessable_type: "Assignment", assessable_id: assignment_no_assessment.id }
        expect(response).to redirect_to(assessment_assessments_path(lecture_id: lecture.id))
      end
    end
  end

  describe "PATCH /assessment/assessments/:id" do
    let!(:assignment) { create(:valid_assignment, lecture: lecture, title: "Old Title") }
    let!(:assessment) { assignment.assessment }

    before { sign_in teacher }

    context "with valid parameters" do
      it "updates the assessment" do
        patch assessment_assessment_path(assessment.id),
              params: {
                assessment_assessment: {
                  assessable_attributes: {
                    id: assignment.id,
                    title: "New Title"
                  }
                }
              },
              as: :turbo_stream
        assignment.reload
        expect(assignment.title).to eq("New Title")
      end

      it "renders turbo_stream" do
        patch assessment_assessment_path(assessment.id),
              params: {
                assessment_assessment: {
                  assessable_attributes: {
                    id: assignment.id,
                    title: "New Title"
                  }
                }
              },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include("assessments_container")
      end
    end

    context "with invalid parameters" do
      it "does not update the assessment" do
        patch assessment_assessment_path(assessment.id),
              params: {
                assessment_assessment: {
                  assessable_attributes: {
                    id: assignment.id,
                    title: ""
                  }
                }
              },
              as: :turbo_stream
        assignment.reload
        expect(assignment.title).to eq("Old Title")
      end

      it "renders unprocessable_content" do
        patch assessment_assessment_path(assessment.id),
              params: {
                assessment_assessment: {
                  assessable_attributes: {
                    id: assignment.id,
                    title: ""
                  }
                }
              },
              as: :turbo_stream
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include("assessments_container")
      end
    end
  end

  describe "PATCH /assessment/assessments/assignments_complete" do
    context "as a teacher" do
      before { sign_in teacher }

      it "offers the statement next to the list it is about" do
        create(:valid_assignment, lecture: lecture)

        get assessment_assessments_path(lecture_id: lecture.id)

        expect(response.body).to include(
          CGI.escapeHTML(I18n.t("assessment.assignments_complete.label"))
        )
      end

      # Both directions turn every eligibility verdict over, so the page asks
      # first - and the question it asks depends on which way the tick is
      # about to go.
      it "asks before closing the list, and says what closing does" do
        create(:valid_assignment, lecture: lecture)

        get assessment_assessments_path(lecture_id: lecture.id)

        expect(response.body).to include(
          CGI.escapeHTML(
            I18n.t("assessment.assignments_complete.close_dialog.body")
          )
        )
      end

      it "asks before reopening a list nobody has decided anything on" do
        create(:valid_assignment, lecture: lecture)
        lecture.update!(assignments_complete: true)

        get assessment_assessments_path(lecture_id: lecture.id)

        expect(response.body).to include(
          CGI.escapeHTML(
            I18n.t("assessment.assignments_complete.open_dialog.body")
          )
        )
        expect(response.body).not_to include(
          I18n.t("assessment.assignments_complete.reopen_dialog.reset")
        )
      end

      it "closes the list" do
        patch assignments_complete_assessment_assessments_path(
          lecture_id: lecture.id, complete: "1"
        )

        expect(lecture.reload.assignments_complete?).to be(true)
        expect(response).to redirect_to(
          assessment_assessments_path(lecture_id: lecture.id,
                                      tab: "assessments")
        )
      end

      it "takes the statement back" do
        lecture.update!(assignments_complete: true)

        patch assignments_complete_assessment_assessments_path(
          lecture_id: lecture.id, complete: "0"
        )

        expect(lecture.reload.assignments_complete?).to be(false)
      end

      context "with decisions on record" do
        let!(:computed) do
          create(:student_performance_certification, :passed, lecture: lecture)
        end

        let!(:manual) do
          create(:student_performance_certification, :failed, :manual,
                 lecture: lecture)
        end

        before { lecture.update!(assignments_complete: true) }

        it "asks before reopening the list" do
          # Creating an assignment clears `assignments_complete`, so it is
          # set again here.
          create(:valid_assignment, lecture: lecture)
          lecture.update!(assignments_complete: true)

          get assessment_assessments_path(lecture_id: lecture.id)

          expect(response.body).to include(
            CGI.escapeHTML(
              I18n.t("assessment.assignments_complete.reopen_dialog.body",
                     count: 1)
            )
          )
        end

        # The list is open, so the question is the other one: what closing it
        # would do. Nothing is said about decisions, because closing leaves
        # them alone.
        it "asks about closing instead while the list is still open" do
          lecture.update!(assignments_complete: false)
          create(:valid_assignment, lecture: lecture)

          get assessment_assessments_path(lecture_id: lecture.id)

          expect(response.body).to include(
            CGI.escapeHTML(
              I18n.t("assessment.assignments_complete.close_dialog.body")
            )
          )
          expect(response.body).not_to include(
            I18n.t("assessment.assignments_complete.reopen_dialog.reset")
          )
        end

        it "keeps the decisions unless told otherwise" do
          patch assignments_complete_assessment_assessments_path(
            lecture_id: lecture.id, complete: "0"
          )

          expect(lecture.reload.assignments_complete?).to be(false)
          expect(StudentPerformance::Certification.exists?(computed.id)).to be(true)
        end

        it "drops the computed decisions when told to, and keeps the manual ones" do
          patch assignments_complete_assessment_assessments_path(
            lecture_id: lecture.id, complete: "0", reset_certifications: "1"
          )

          expect(lecture.reload.assignments_complete?).to be(false)
          expect(StudentPerformance::Certification.exists?(computed.id)).to be(false)
          expect(StudentPerformance::Certification.exists?(manual.id)).to be(true)
        end

        # The dialog is shown while the list is closed. Sending its answer a
        # second time must not undo a "keep" from the first one.
        it "does not drop anything when the list is open already" do
          lecture.update!(assignments_complete: false)

          patch assignments_complete_assessment_assessments_path(
            lecture_id: lecture.id, complete: "0", reset_certifications: "1"
          )

          expect(StudentPerformance::Certification.exists?(computed.id)).to be(true)
        end

        it "does not drop anything when closing the list" do
          lecture.update!(assignments_complete: false)

          patch assignments_complete_assessment_assessments_path(
            lecture_id: lecture.id, complete: "1", reset_certifications: "1"
          )

          expect(StudentPerformance::Certification.exists?(computed.id)).to be(true)
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch assignments_complete_assessment_assessments_path(
          lecture_id: lecture.id, complete: "1"
        )

        expect(response).to redirect_to(root_path)
        expect(lecture.reload.assignments_complete?).to be(false)
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
