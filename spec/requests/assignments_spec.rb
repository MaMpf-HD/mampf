require "rails_helper"

RSpec.describe("Assignments", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let!(:assignment) { create(:valid_assignment, lecture: lecture) }

  before do
    Flipper.enable(:assessment_grading)
    create(:editable_user_join, user: editor, editable: lecture)
  end

  after do
    Flipper.disable(:assessment_grading)
  end

  describe "GET /assignments/new" do
    context "as a teacher" do
      before { sign_in teacher }

      it "returns http success with turbo_stream" do
        get new_assignment_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "renders the form" do
        get new_assignment_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response.body).to include("assignment_form_container")
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get new_assignment_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        get new_assignment_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET /assignments/:id/edit" do
    context "as a teacher" do
      before { sign_in teacher }

      it "returns http success with turbo_stream" do
        get edit_assignment_path(assignment), as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "renders the form with assignment data" do
        get edit_assignment_path(assignment), as: :turbo_stream
        expect(response.body).to include("assignment_form_container")
        expect(response.body).to include(assignment.title)
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get edit_assignment_path(assignment), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        get edit_assignment_path(assignment), as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "POST /assignments" do
    let(:valid_attributes) do
      {
        title: "New Assignment",
        lecture_id: lecture.id,
        deadline: 2.weeks.from_now.iso8601,
        deletion_date: 4.weeks.from_now.iso8601,
        accepted_file_type: ".pdf"
      }
    end

    let(:invalid_attributes) do
      {
        title: "",
        lecture_id: lecture.id,
        deadline: 1.day.ago.iso8601,
        deletion_date: 2.days.from_now.iso8601
      }
    end

    context "as a teacher" do
      before { sign_in teacher }

      context "with valid parameters" do
        it "creates a new assignment" do
          expect do
            post(assignments_path,
                 params: { assignment: valid_attributes },
                 as: :turbo_stream)
          end.to change(Assignment, :count).by(1)
        end

        it "creates an associated assessment" do
          expect do
            post(assignments_path,
                 params: { assignment: valid_attributes },
                 as: :turbo_stream)
          end.to change(Assessment::Assessment, :count).by(1)
        end

        it "renders a successful turbo_stream response" do
          post assignments_path,
               params: { assignment: valid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end

        it "clears the form container" do
          post assignments_path,
               params: { assignment: valid_attributes },
               as: :turbo_stream
          expect(response.body).to include("assignment_form_container")
        end

        it "prepends the new assignment to the list" do
          post assignments_path,
               params: { assignment: valid_attributes },
               as: :turbo_stream
          expect(response.body).to include("assessment-assessments-list")
        end
      end

      context "with invalid parameters" do
        it "does not create a new assignment" do
          expect do
            post(assignments_path,
                 params: { assignment: invalid_attributes },
                 as: :turbo_stream)
          end.not_to change(Assignment, :count)
        end

        it "renders an unprocessable_content response" do
          post assignments_path,
               params: { assignment: invalid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "renders the form with errors" do
          post assignments_path,
               params: { assignment: invalid_attributes },
               as: :turbo_stream
          expect(response.body).to include("assignment_form_container")
        end
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "creates a new assignment" do
        expect do
          post(assignments_path,
               params: { assignment: valid_attributes },
               as: :turbo_stream)
        end.to change(Assignment, :count).by(1)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        post assignments_path,
             params: { assignment: valid_attributes },
             as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "PATCH /assignments/:id" do
    let(:valid_attributes) do
      {
        title: "Updated Assignment Title",
        deadline: 3.weeks.from_now.iso8601,
        accepted_file_type: ".zip"
      }
    end

    let(:invalid_attributes) do
      {
        title: "",
        deadline: 1.day.ago.iso8601,
        deletion_date: assignment.deletion_date.iso8601
      }
    end

    context "as a teacher" do
      before { sign_in teacher }

      context "with valid parameters" do
        it "updates the assignment" do
          patch assignment_path(assignment),
                params: { assignment: valid_attributes },
                as: :turbo_stream
          assignment.reload
          expect(assignment.title).to eq("Updated Assignment Title")
          expect(assignment.accepted_file_type).to eq(".zip")
        end

        it "renders a successful turbo_stream response" do
          patch assignment_path(assignment),
                params: { assignment: valid_attributes },
                as: :turbo_stream
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end

        it "clears the form container" do
          patch assignment_path(assignment),
                params: { assignment: valid_attributes },
                as: :turbo_stream
          expect(response.body).to include("assignment_form_container")
        end

        it "replaces the assignment in the list" do
          patch assignment_path(assignment),
                params: { assignment: valid_attributes },
                as: :turbo_stream
          expect(response.body).to include(ActionView::RecordIdentifier.dom_id(assignment))
        end

        context "when clearing medium_id" do
          let(:medium) do
            create(:medium, :with_description, :with_editors, teachable: lecture, released: "all",
                                                              sort: "Script")
          end

          before do
            assignment.update!(medium: medium)
          end

          it "removes the medium association" do
            patch assignment_path(assignment),
                  params: { assignment: valid_attributes.merge(medium_id: "") },
                  as: :turbo_stream
            assignment.reload
            expect(assignment.medium).to be_nil
          end
        end
      end

      context "with invalid parameters" do
        it "does not update the assignment" do
          original_title = assignment.title
          patch assignment_path(assignment),
                params: { assignment: invalid_attributes },
                as: :turbo_stream
          assignment.reload
          expect(assignment.title).to eq(original_title)
        end

        it "renders an unprocessable_content response" do
          patch assignment_path(assignment),
                params: { assignment: invalid_attributes },
                as: :turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "renders the form with errors" do
          patch assignment_path(assignment),
                params: { assignment: invalid_attributes },
                as: :turbo_stream
          expect(response.body).to include("assignment_form_container")
        end
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "updates the assignment" do
        patch assignment_path(assignment),
              params: { assignment: valid_attributes },
              as: :turbo_stream
        assignment.reload
        expect(assignment.title).to eq("Updated Assignment Title")
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        patch assignment_path(assignment),
              params: { assignment: valid_attributes },
              as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "DELETE /assignments/:id" do
    context "as a teacher" do
      before { sign_in teacher }

      it "destroys the assignment" do
        expect do
          delete(assignment_path(assignment), as: :turbo_stream)
        end.to change(Assignment, :count).by(-1)
      end

      it "destroys the associated assessment" do
        fresh_assignment = create(:valid_assignment, lecture: lecture)
        assessment_id = fresh_assignment.reload.assessment.id

        delete assignment_path(fresh_assignment), as: :turbo_stream
        expect { Assessment::Assessment.find(assessment_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "destroys associated participations" do
        fresh_assignment = create(:valid_assignment, lecture: lecture)
        assessment = fresh_assignment.reload.assessment
        student_user = create(:confirmed_user)
        create(:assessment_participation, assessment: assessment, user: student_user)

        expect do
          delete(assignment_path(fresh_assignment), as: :turbo_stream)
        end.to change(Assessment::Participation, :count).by(-1)
      end

      it "renders a successful turbo_stream response" do
        delete assignment_path(assignment), as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "removes the assignment from the list" do
        delete assignment_path(assignment), as: :turbo_stream
        expect(response.body).to include(ActionView::RecordIdentifier.dom_id(assignment))
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "destroys the assignment" do
        expect do
          delete(assignment_path(assignment), as: :turbo_stream)
        end.to change(Assignment, :count).by(-1)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        delete assignment_path(assignment), as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end

      it "does not destroy the assignment" do
        expect do
          delete(assignment_path(assignment), as: :turbo_stream)
        end.not_to change(Assignment, :count)
      end
    end
  end

  describe "GET /assignments/cancel_edit" do
    context "as a teacher" do
      before { sign_in teacher }

      it "returns http success with turbo_stream" do
        get cancel_edit_assignment_path(assignment), as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "clears the form container" do
        get cancel_edit_assignment_path(assignment), as: :turbo_stream
        expect(response.body).to include("assignment_form_container")
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get cancel_edit_assignment_path(assignment), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /assignments/cancel_new" do
    context "as a teacher" do
      before { sign_in teacher }

      it "returns http success with turbo_stream" do
        get cancel_new_assignment_path(lecture: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "clears the form container" do
        get cancel_new_assignment_path(lecture: lecture.id), as: :turbo_stream
        expect(response.body).to include("assignment_form_container")
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get cancel_new_assignment_path(lecture: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        get cancel_new_assignment_path(lecture: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "when assignment does not exist" do
    context "as a teacher" do
      before { sign_in teacher }

      it "redirects to root for edit" do
        get edit_assignment_path(id: 99_999), as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end

      it "redirects to root for update" do
        patch assignment_path(id: 99_999),
              params: { assignment: { title: "Test" } },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end

      it "redirects to root for destroy" do
        delete assignment_path(id: 99_999), as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "locale handling" do
    let(:german_lecture) do
      create(:lecture, :released_for_all, teacher: teacher,
                                          locale: "de", course: create(:course, locale: "de"))
    end
    let(:german_assignment) { create(:valid_assignment, lecture: german_lecture) }

    context "as a teacher" do
      before { sign_in teacher }

      it "uses lecture locale for new" do
        get new_assignment_path(lecture_id: german_lecture.id), as: :turbo_stream
        expect(I18n.locale).to eq(:de)
      end

      it "uses lecture locale for edit" do
        get edit_assignment_path(german_assignment), as: :turbo_stream
        expect(I18n.locale).to eq(:de)
      end

      it "uses lecture locale for create" do
        post assignments_path,
             params: {
               assignment: {
                 title: "Test",
                 lecture_id: german_lecture.id,
                 deadline: 2.weeks.from_now.iso8601,
                 deletion_date: 4.weeks.from_now.iso8601,
                 accepted_file_type: ".pdf"
               }
             },
             as: :turbo_stream
        expect(I18n.locale).to eq(:de)
      end

      it "uses lecture locale for update" do
        patch assignment_path(german_assignment),
              params: { assignment: { title: "Updated" } },
              as: :turbo_stream
        expect(I18n.locale).to eq(:de)
      end
    end
  end
end
