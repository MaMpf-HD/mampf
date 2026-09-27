require "rails_helper"

RSpec.describe("Exams", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }

  before do
    create(:editable_user_join, user: editor, editable: lecture)
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
        expect(response.body).to include("id=\"dashboard-exam-#{exam.id}\"")
      end

      # The dashboard is a fragment of the lecture's exam tab, so a direct visit
      # belongs there rather than on a page that does not exist.
      it "sends a direct visit to the lecture's exam tab" do
        get exam_path(exam)
        expect(response).to redirect_to(
          edit_lecture_path(exam.lecture, tab: "exams")
        )
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

    describe "schedule change notification" do
      let!(:participant) { create(:confirmed_user, locale: "en") }

      before do
        create(:exam_roster_entry, exam: exam, user: participant)
        sign_in teacher
      end

      context "when date changes" do
        let(:valid_attributes_new_date) do
          {
            date: 5.weeks.from_now.strftime("%Y-%m-%d %H:%M")
          }
        end
        it "sends a schedule change email to participants" do
          perform_enqueued_jobs do
            expect do
              patch(exam_path(exam),
                    params: { exam: valid_attributes_new_date },
                    as: :turbo_stream)
            end.to change { ActionMailer::Base.deliveries.count }.by(1)
          end
        end
      end

      context "when location changes" do
        let(:valid_attributes_new_location) do
          {
            location: "Room 202"
          }
        end
        it "sends a schedule change email to participants" do
          perform_enqueued_jobs do
            expect do
              patch(exam_path(exam),
                    params: { exam: valid_attributes_new_location },
                    as: :turbo_stream)
            end.to change { ActionMailer::Base.deliveries.count }.by(1)
          end
        end
      end

      context "when both date and location change" do
        let(:valid_attributes_new_date_and_location) do
          {
            date: 5.weeks.from_now.strftime("%Y-%m-%d %H:%M"),
            location: "Room 101"
          }
        end
        it "sends only one email per participant" do
          perform_enqueued_jobs do
            expect do
              patch(exam_path(exam),
                    params: { exam: valid_attributes_new_date_and_location },
                    as: :turbo_stream)
            end.to change { ActionMailer::Base.deliveries.count }.by(1)
          end
        end
      end

      context "when neither date nor location changes" do
        let(:valid_attributes_new_name) do
          {
            title: "Updated Exam Title",
            location: exam.location,
            capacity: 75
          }
        end
        it "does not send an email" do
          perform_enqueued_jobs do
            expect do
              patch(exam_path(exam),
                    params: { exam: valid_attributes_new_name },
                    as: :turbo_stream)
            end.not_to(change { ActionMailer::Base.deliveries.count })
          end
        end
      end

      context "when the update is invalid due to missing title" do
        it "does not send an email" do
          perform_enqueued_jobs do
            expect do
              patch(exam_path(exam),
                    params: { exam: { title: "",
                                      date: 5.weeks.from_now.strftime("%Y-%m-%d %H:%M") } },
                    as: :turbo_stream)
            end.not_to(change { ActionMailer::Base.deliveries.count })
          end
        end
      end

      context "when there are no participants" do
        it "does not attempt to send email" do
          perform_enqueued_jobs do
            expect do
              patch(exam_path(exam.tap { |e| e.exam_roster_entries.destroy_all }),
                    params: { exam: { location: "Room 999" } },
                    as: :turbo_stream)
            end.not_to(change { ActionMailer::Base.deliveries.count })
          end
        end
      end

      context "with multiple participants" do
        let!(:other_participant) { create(:confirmed_user, locale: "en") }

        before { create(:exam_roster_entry, exam: exam, user: other_participant) }

        it "sends an email to every participant" do
          perform_enqueued_jobs do
            expect do
              patch(exam_path(exam),
                    params: { exam: { location: "Room 999" } },
                    as: :turbo_stream)
            end.to change { ActionMailer::Base.deliveries.count }.by(2)
          end

          recipients = ActionMailer::Base.deliveries.last(2).flat_map(&:to)
          expect(recipients).to contain_exactly(participant.email, other_participant.email)
        end
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

  describe "POST /exams/:id/participants" do
    let(:new_student) { create(:confirmed_user, locale: "en") }

    context "as a teacher" do
      before { sign_in teacher }

      it "adds the user as a participant" do
        expect do
          post(participants_exam_path(exam), params: { user_id: new_student.id }, as: :turbo_stream)
        end.to change { exam.roster_entries.count }.by(1)
      end

      it "sends an email when a participant is successfully added" do
        perform_enqueued_jobs do
          expect do
            post(participants_exam_path(exam), params: { user_id: new_student.id },
                                               as: :turbo_stream)
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(new_student.locale) do
          I18n.t("roster.mailer.roster_added_to_exam_email_subject",
                 rosterable_title: exam.title,
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
        expect(email.to).to eq([new_student.email])
      end

      context "when the user is already registered" do
        before { create(:exam_roster_entry, exam: exam, user: new_student) }

        it "does not send a duplicate email" do
          perform_enqueued_jobs do
            expect do
              post(participants_exam_path(exam), params: { user_id: new_student.id },
                                                 as: :turbo_stream)
            end.not_to(change { ActionMailer::Base.deliveries.count })
          end
        end
      end

      context "when the user is not found" do
        it "does not send an email" do
          perform_enqueued_jobs do
            expect do
              post(participants_exam_path(exam), params: { user_id: 99_999 }, as: :turbo_stream)
            end.not_to(change { ActionMailer::Base.deliveries.count })
          end
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "does not send an email" do
        perform_enqueued_jobs do
          expect do
            post(participants_exam_path(exam), params: { user_id: new_student.id },
                                               as: :turbo_stream)
          end.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end
    end
  end

  describe "DELETE /exams/:id/participants/:user_id" do
    let(:member) { create(:confirmed_user, locale: "en") }

    before { create(:exam_roster_entry, exam: exam, user: member) }

    context "as a teacher" do
      before { sign_in teacher }

      it "removes the user from the exam roster" do
        expect do
          delete(remove_participant_exam_path(exam, user_id: member.id), as: :turbo_stream)
        end.to change { exam.roster_entries.count }.by(-1)
      end

      it "sends an email when a participant is successfully removed" do
        perform_enqueued_jobs do
          expect do
            delete(remove_participant_exam_path(exam, user_id: member.id), as: :turbo_stream)
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        email = ActionMailer::Base.deliveries.last
        expected_subject = I18n.with_locale(member.locale) do
          I18n.t("roster.mailer.roster_removed_from_exam_email_subject",
                 rosterable_title: exam.title,
                 lecture_title: lecture.title)
        end
        expect(email.subject).to eq(expected_subject)
      end

      context "when removal is blocked" do
        before { allow_any_instance_of(Exam).to receive(:participant_removable?).and_return(false) }

        it "does not send an email" do
          perform_enqueued_jobs do
            expect do
              delete(remove_participant_exam_path(exam, user_id: member.id), as: :turbo_stream)
            end.not_to(change { ActionMailer::Base.deliveries.count })
          end
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "does not send an email" do
        perform_enqueued_jobs do
          expect do
            delete(remove_participant_exam_path(exam, user_id: member.id), as: :turbo_stream)
          end.not_to(change { ActionMailer::Base.deliveries.count })
        end
      end
    end
  end
end
