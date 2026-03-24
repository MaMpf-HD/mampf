require "rails_helper"

RSpec.describe("Exams", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let!(:exam) { create(:exam, lecture: lecture) }

  before do
    Flipper.enable(:assessment_grading)
    create(:editable_user_join, user: editor, editable: lecture)
  end

  after do
    Flipper.disable(:assessment_grading)
  end

  describe "GET /exams" do
    context "as a teacher" do
      before { sign_in teacher }

      it "returns http success" do
        get exams_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      it "renders the exams list" do
        get exams_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response.body).to include(exam.title)
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get exams_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        get exams_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET /exams/new" do
    context "as a teacher" do
      before { sign_in teacher }

      it "returns http success with turbo_stream" do
        get new_exam_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "renders the form" do
        get new_exam_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response.body).to include("exams_container")
        expect(response.body).to include("form")
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get new_exam_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        get new_exam_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end
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

    let(:invalid_attributes) do
      {
        title: "",
        lecture_id: lecture.id
      }
    end

    context "as a teacher" do
      before { sign_in teacher }

      context "with valid parameters" do
        it "creates a new exam" do
          expect do
            post(exams_path,
                 params: { exam: valid_attributes },
                 as: :turbo_stream)
          end.to change(Exam, :count).by(1)
        end

        it "renders a successful turbo_stream response" do
          post exams_path,
               params: { exam: valid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end

        it "updates the exams container" do
          post exams_path,
               params: { exam: valid_attributes },
               as: :turbo_stream
          expect(response.body).to include("exams_container")
        end

        context "when registration_campaigns is enabled" do
          before { Flipper.enable(:registration_campaigns) }
          after { Flipper.disable(:registration_campaigns) }

          it "auto-creates a registration campaign" do
            expect do
              post(exams_path,
                   params: { exam: valid_attributes },
                   as: :turbo_stream)
            end.to change(Registration::Campaign, :count).by(1)

            exam = Exam.order(created_at: :desc).first
            campaign = exam.registration_campaign
            expect(campaign).to be_present
            expect(campaign).to be_draft
            expect(campaign).to be_first_come_first_served
          end

          it "uses registration_deadline when provided" do
            deadline = 3.weeks.from_now.beginning_of_hour
            attrs = valid_attributes.merge(
              registration_deadline: deadline.strftime("%Y-%m-%d %H:%M")
            )
            post(exams_path,
                 params: { exam: attrs },
                 as: :turbo_stream)

            exam = Exam.order(created_at: :desc).first
            expect(exam.registration_campaign.registration_deadline)
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
      end

      context "with invalid parameters" do
        it "does not create a new exam" do
          expect do
            post(exams_path,
                 params: { exam: invalid_attributes },
                 as: :turbo_stream)
          end.not_to change(Exam, :count)
        end

        it "renders an unprocessable_content response" do
          post exams_path,
               params: { exam: invalid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "renders the form with errors" do
          post exams_path,
               params: { exam: invalid_attributes },
               as: :turbo_stream
          expect(response.body).to include("exams_container")
          expect(response.body).to include("is-invalid")
        end
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "creates a new exam" do
        expect do
          post(exams_path,
               params: { exam: valid_attributes },
               as: :turbo_stream)
        end.to change(Exam, :count).by(1)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        post exams_path,
             params: { exam: valid_attributes },
             as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET /exams/:id/edit" do
    context "as a teacher" do
      before { sign_in teacher }

      it "returns http success with turbo_stream" do
        get edit_exam_path(exam), as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "renders the form with exam data" do
        get edit_exam_path(exam), as: :turbo_stream
        expect(response.body).to include("exams_container")
        expect(response.body).to include(exam.title)
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get edit_exam_path(exam), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        get edit_exam_path(exam), as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "PATCH /exams/:id" do
    let(:valid_attributes) do
      {
        title: "Updated Exam Title",
        location: "Room 202",
        capacity: 75
      }
    end

    let(:invalid_attributes) do
      {
        title: ""
      }
    end

    context "as a teacher" do
      before { sign_in teacher }

      context "with valid parameters" do
        it "updates the exam" do
          patch exam_path(exam),
                params: { exam: valid_attributes },
                as: :turbo_stream
          exam.reload
          expect(exam.title).to eq("Updated Exam Title")
          expect(exam.location).to eq("Room 202")
          expect(exam.capacity).to eq(75)
        end

        it "renders a successful response" do
          patch exam_path(exam),
                params: { exam: valid_attributes },
                as: :turbo_stream
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end

        it "updates the exams container" do
          patch exam_path(exam),
                params: { exam: valid_attributes },
                as: :turbo_stream
          expect(response.body).to include("exams_container")
        end
      end

      context "with invalid parameters" do
        it "does not update the exam" do
          original_title = exam.title
          patch exam_path(exam),
                params: { exam: invalid_attributes },
                as: :turbo_stream
          exam.reload
          expect(exam.title).to eq(original_title)
        end

        it "renders an unprocessable_content response" do
          patch exam_path(exam),
                params: { exam: invalid_attributes },
                as: :turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "renders the form with errors" do
          patch exam_path(exam),
                params: { exam: invalid_attributes },
                as: :turbo_stream
          expect(response.body).to include("exams_container")
          expect(response.body).to include("is-invalid")
        end
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "updates the exam" do
        patch exam_path(exam),
              params: { exam: valid_attributes },
              as: :turbo_stream
        exam.reload
        expect(exam.title).to eq("Updated Exam Title")
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        patch exam_path(exam),
              params: { exam: valid_attributes },
              as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "DELETE /exams/:id" do
    context "as a teacher" do
      before { sign_in teacher }

      context "when exam is destructible" do
        it "destroys the requested exam" do
          expect do
            delete(exam_path(exam), as: :turbo_stream)
          end.to change(Exam, :count).by(-1)
        end

        it "renders a successful response" do
          delete exam_path(exam), as: :turbo_stream
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end

        it "renders the updated exams list" do
          delete exam_path(exam), as: :turbo_stream
          expect(response.body).to include("exams_container")
        end
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "destroys the exam" do
        expect do
          delete(exam_path(exam), as: :turbo_stream)
        end.to change(Exam, :count).by(-1)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        delete exam_path(exam), as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
