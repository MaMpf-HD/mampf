require "rails_helper"

RSpec.describe("Exams", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }

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
        exam
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
            deadline = 1.week.from_now.beginning_of_hour
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

  describe "GET /exams/:id" do
    context "as a teacher" do
      before { sign_in teacher }

      it "returns http success with turbo_stream" do
        get exam_path(exam), as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "renders the assessment dashboard" do
        get exam_path(exam), as: :turbo_stream
        expect(response.body).to include("exams_container")
        expect(response.body).to include("data-cy=\"assessment-dashboard\"")
      end

      context "when registration_campaigns is enabled" do
        before { Flipper.enable(:registration_campaigns) }
        after { Flipper.disable(:registration_campaigns) }

        it "renders the registration tab and inline policies in settings" do
          get exam_path(exam), as: :turbo_stream

          expect(response).to have_http_status(:success)
          expect(response.body).to include(
            "data-bs-target=\"#dashboard-exam-#{exam.id}-registration\""
          )
          expect(response.body).to include(
            I18n.t("registration.policy.index.title")
          )
          expect(response.body).to include(
            I18n.t("registration.campaign.actions.open")
          )
          expect(response.body).not_to include(
            I18n.t("assessment.info_bar.go_to_registration")
          )
          expect(response.body).not_to include("-policies\"")
        end

        it "renders the deadline form disabled for a closed campaign" do
          exam.registration_campaign.update!(status: :closed)

          get exam_path(exam), params: { tab: "registration" }, as: :turbo_stream

          document = Nokogiri::HTML.fragment(response.body)
          deadline_input = document.at_css("#exam_registration_deadline")

          expect(response).to have_http_status(:success)
          expect(deadline_input).to be_present
          expect(deadline_input["disabled"]).to eq("disabled")
          expect(response.body).not_to include("exams--registration-settings")
        end
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get exam_path(exam), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects unauthorized users" do
        get exam_path(exam), as: :turbo_stream
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

        it "reopens the campaign when saving a deadline fix for reopen" do
          Flipper.enable(:registration_campaigns)
          campaign = exam.registration_campaign
          campaign.update!(status: :closed)

          deadline = 1.week.from_now.beginning_of_hour

          patch(exam_path(exam),
                params: {
                  exam: {
                    registration_deadline: deadline.strftime("%Y-%m-%d %H:%M")
                  },
                  tab: "registration",
                  reopen_after_deadline_fix: "1"
                },
                as: :turbo_stream)

          campaign.reload
          expect(campaign).to be_open
          expect(campaign.registration_deadline).to be_within(1.minute).of(deadline)
          expect(response).to have_http_status(:ok)
        ensure
          Flipper.disable(:registration_campaigns)
        end

        it "does not change the deadline for a closed campaign without reopen mode" do
          Flipper.enable(:registration_campaigns)
          campaign = exam.registration_campaign
          campaign.update!(status: :closed)
          original_deadline = campaign.registration_deadline

          patch(exam_path(exam),
                params: {
                  exam: {
                    registration_deadline: 1.week.from_now.beginning_of_hour.strftime(
                      "%Y-%m-%d %H:%M"
                    )
                  },
                  tab: "registration"
                },
                as: :turbo_stream)

          campaign.reload
          expect(campaign.registration_deadline).to eq(original_deadline)
          expect(response).to have_http_status(:ok)
        ensure
          Flipper.disable(:registration_campaigns)
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

  describe "POST /exams/:id/participants" do
    before { sign_in teacher }

    context "with registration campaigns enabled" do
      let(:campaign) { exam.registration_campaign }

      before do
        Flipper.enable(:registration_campaigns)
        campaign.update!(status: :completed)
      end

      after do
        Flipper.disable(:registration_campaigns)
      end

      it "adds a rejected registration to the participants list by user id" do
        registration = create(:registration_user_registration,
                              :rejected,
                              registration_campaign: campaign,
                              registration_item: campaign.registration_items.first,
                              user: student,
                              rejection_reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_MANUAL,
                              rejection_reason_code: Registration::UserRegistration::REJECTION_REASON_CODE_WITHDRAWN_BY_TEACHER,
                              rejection_reason_label: I18n.t(
                                "registration.user_registration.reason_labels.withdrawn_by_teacher"
                              ))

        expect do
          post(participants_exam_path(exam),
               params: { user_id: student.id },
               as: :turbo_stream)
        end.to change { exam.reload.exam_roster_entries.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(registration.reload).to be_rejected
        expect(registration.rejection_overridden_at).to be_nil
      end

      it "reinstates an excluded participant by user id" do
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
        expect(exam.reload.exam_roster_entries.map(&:user_id)).to include(student.id)
      end
    end
  end

  describe "DELETE /exams/:id/participants/:user_id" do
    before { sign_in teacher }

    context "with registration campaigns enabled" do
      let(:campaign) { exam.registration_campaign }

      before do
        Flipper.enable(:registration_campaigns)
        create(:exam_roster_entry, exam: exam, user: student)
        campaign.update!(status: :completed)
      end

      after do
        Flipper.disable(:registration_campaigns)
      end

      it "blocks removal when grading data already exists" do
        assessment = exam.assessment
        assessment.update!(requires_points: true)
        task = create(:assessment_task, assessment: assessment)
        participation = create(:assessment_participation,
                               assessment: assessment,
                               user: student,
                               status: :pending,
                               submitted_at: nil)
        create(:assessment_task_point,
               task: task,
               assessment_participation: participation)

        expect do
          delete(remove_participant_exam_path(exam, user_id: student.id),
                 as: :turbo_stream)
        end.not_to(change { exam.reload.exam_roster_entries.count })

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(
          I18n.t("assessment.registration_tab.remove_blocked")
        )
      end
    end
  end

  describe "DELETE /exams/:id" do
    context "as a teacher" do
      before { sign_in teacher }

      context "when exam is destructible" do
        it "destroys the requested exam" do
          exam
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
        exam
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
