require "rails_helper"

RSpec.describe(Assessment::GradesController, type: :request) do
  let(:teacher) { FactoryBot.create(:confirmed_user) }
  let(:student) { FactoryBot.create(:confirmed_user) }

  describe "Talk" do
    let(:seminar) do
      FactoryBot.create(:lecture, :released_for_all, sort: "seminar", teacher: teacher)
    end
    let(:talk) { FactoryBot.create(:talk, lecture: seminar, dates: [1.week.from_now]) }
    let(:speaker) { FactoryBot.create(:confirmed_user) }
    let(:assessment) { talk.reload.assessment }
    let(:grader) { teacher }
    let!(:participation) do
      FactoryBot.create(:assessment_participation, assessment: assessment, user: speaker)
    end
    let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    before do
      FactoryBot.create(:speaker_talk_join, talk: talk, speaker: speaker)
      sign_in grader
    end

    describe "PATCH #update" do
      subject do
        patch grade_participation_path(participation),
              params: { grade: "1.0", comment: "well done" },
              headers: turbo_stream_headers
      end

      context "when the grade is set successfully" do
        it "returns a successful turbo_stream response" do
          subject
          expect(response).to have_http_status(:ok)
        end

        it "persists the grade via TalkGraderService" do
          expect(Assessment::TalkGraderService).to receive(:set_grade).with(
            instance_of(Assessment::Participation), "1.0", grader, "well done"
          ).and_call_original

          subject
        end

        it "renders the replaced participation row" do
          subject
          expect(response.body).to include("participation-row-#{participation.id}")
        end

        it "counts the row as graded in the summary" do
          subject
          summary = Nokogiri::HTML(response.body).at_css("turbo-stream[target=pointing-summary]")

          expect(summary.text).to include(
            I18n.t("assessment.grading_tutorial.summary.reviewed", count: 1)
          )
        end

        it "sets a success flash notice" do
          subject
          expect(flash.now[:notice]).to eq(I18n.t("assessment.grades_updated"))
        end
      end

      context "when TalkGraderService raises TalkGraderError" do
        before do
          allow(Assessment::TalkGraderService).to receive(:set_grade)
            .and_raise(Assessment::TalkGraderService::TalkGraderError, "bad grade")
        end

        it "rescues the error instead of raising a 500" do
          expect { subject }.not_to raise_error
        end

        it "responds with the alert flash" do
          subject
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("bad grade")
        end
      end

      context "when GradeEntryService raises GradeEntryError" do
        before do
          allow(Assessment::TalkGraderService).to receive(:set_grade)
            .and_raise(Assessment::GradeEntryService::GradeEntryError, "invalid entry")
        end

        it "rescues the error instead of raising a 500" do
          expect { subject }.not_to raise_error
        end

        it "responds with the alert flash" do
          subject
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("invalid entry")
        end
      end

      context "when participation_id does not exist" do
        subject do
          patch grade_participation_path(participation_id: -1),
                params: { grade: "1.0" },
                headers: turbo_stream_headers
        end

        it "rescues ActiveRecord::RecordNotFound instead of raising a 500" do
          expect { subject }.not_to raise_error
        end

        it "responds with the invalid params alert" do
          subject
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(
            I18n.t("assessment.errors.invalid_request_params")
          )
        end
      end

      context "when the user is not a speaker on the talk" do
        let(:non_speaker_participation) do
          other_user = FactoryBot.create(:confirmed_user)
          FactoryBot.create(:assessment_participation, assessment: assessment, user: other_user)
        end

        subject do
          patch grade_participation_path(non_speaker_participation),
                params: { grade: "1.0" },
                headers: turbo_stream_headers
        end

        it "responds with the user_not_speaker alert" do
          subject
          expect(response.body).to include(
            I18n.t("assessment.talk_grader.user_not_speaker")
          )
        end

        it "does not call TalkGraderService" do
          expect(Assessment::TalkGraderService).not_to receive(:set_grade)
          subject
        end

        it "does not double-render" do
          expect { subject }.not_to raise_error(AbstractController::DoubleRenderError)
        end
      end

      context "as the teacher of another seminar" do
        let(:grader) { FactoryBot.create(:confirmed_user) }

        before { FactoryBot.create(:lecture, sort: "seminar", teacher: grader) }

        it "is turned away and changes nothing" do
          subject

          expect(response).to redirect_to(root_path)
          expect(participation.reload.grade_numeric).to be_nil
        end

        it "may not read a row through refresh either" do
          patch refresh_grade_participation_path(participation), headers: turbo_stream_headers

          expect(response).to redirect_to(root_path)
        end
      end

      context "as a speaker" do
        let(:grader) { speaker }

        it "is turned away" do
          subject

          expect(response).to redirect_to(root_path)
          expect(participation.reload.grade_numeric).to be_nil
        end
      end

      context "when the record refuses the save" do
        it "answers with the record's reason" do
          allow(Assessment::GradeEntryService).to receive(:set_grade) do |record, *|
            record.errors.add(:note, :too_long, count: 255)
            raise(ActiveRecord::RecordInvalid, record)
          end

          subject

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(
            participation.errors.generate_message(:note, :too_long, count: 255)
          )
          expect(response.body).not_to include(I18n.t("assessment.errors.invalid_request_params"))
        end
      end

      context "when the participation belongs to a sheet, not a talk" do
        let(:sheet_participation) do
          lecture = FactoryBot.create(:lecture, teacher: teacher)
          assignment = FactoryBot.create(:assignment, lecture: lecture)
          FactoryBot.create(:assessment_participation, assessment: assignment.reload.assessment,
                                                       user: speaker)
        end

        # The answer says what the row is only to somebody who may grade there.
        it "tells an outsider nothing about the row" do
          sign_in FactoryBot.create(:confirmed_user)

          patch grade_participation_path(sheet_participation),
                params: { grade: "1.0" },
                headers: turbo_stream_headers

          expect(response).to redirect_to(root_path)
        end

        it "turns the grade away with the not-gradable alert" do
          patch grade_participation_path(sheet_participation),
                params: { grade: "1.0" },
                headers: turbo_stream_headers

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(I18n.t("assessment.errors.not_gradable"))
          expect(sheet_participation.reload.grade_numeric).to be_nil
        end

        it "turns the refresh away the same way" do
          patch refresh_grade_participation_path(sheet_participation), headers: turbo_stream_headers

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(I18n.t("assessment.errors.not_gradable"))
        end
      end
    end

    describe "PATCH #refresh" do
      subject do
        patch refresh_grade_participation_path(participation),
              headers: turbo_stream_headers
      end

      it "returns a successful turbo_stream response" do
        subject
        expect(response).to have_http_status(:ok)
      end

      it "re-renders the participation row" do
        subject
        expect(response.body).to include("participation-row-#{participation.id}")
      end

      # Somebody else may have graded since the page was drawn; the reloaded row
      # must not stand next to a line that still counts it as pending.
      it "brings the summary along with the reloaded row" do
        participation.update!(grade_numeric: 1.0, status: :reviewed, graded_at: 1.minute.ago,
                              grader: teacher)

        subject

        summary = Nokogiri::HTML(response.body).at_css("turbo-stream[target=pointing-summary]")
        expect(summary.text).to include(
          I18n.t("assessment.grading_tutorial.summary.reviewed", count: 1)
        )
      end

      context "when participation_id does not exist" do
        subject do
          patch refresh_grade_participation_path(participation_id: -1),
                headers: turbo_stream_headers
        end

        it "rescues ActiveRecord::RecordNotFound instead of raising a 500" do
          expect { subject }.not_to raise_error
        end

        it "responds with the invalid params alert" do
          subject
          expect(response.body).to include(
            I18n.t("assessment.errors.invalid_request_params")
          )
        end
      end

      context "when the user is not a speaker on the talk" do
        let(:non_speaker_participation) do
          other_user = FactoryBot.create(:confirmed_user)
          FactoryBot.create(:assessment_participation, assessment: assessment, user: other_user)
        end

        subject do
          patch refresh_grade_participation_path(non_speaker_participation),
                headers: turbo_stream_headers
        end

        it "responds with the user_not_speaker alert" do
          subject
          expect(response.body).to include(
            I18n.t("assessment.talk_grader.user_not_speaker")
          )
        end
      end
    end
  end

  describe "Exam" do
    let(:lecture) { FactoryBot.create(:lecture, :released_for_all, teacher: teacher) }
    let(:exam) { FactoryBot.create(:exam, lecture: lecture) }
    let(:exam_assessment) { FactoryBot.create(:assessment, :with_points, assessable: exam) }
    let(:exam_student) { FactoryBot.create(:confirmed_user) }
    let!(:exam_participation) do
      FactoryBot.create(:assessment_participation, assessment: exam_assessment,
                                                   user: exam_student)
    end
    describe "PATCH #update (exam)" do
      subject do
        patch grade_participation_path(exam_participation),
              params: { grade: "1.7", comment: "oral exam" },
              headers: turbo_stream_headers
      end

      context "when the grade is set successfully" do
        it "returns a successful turbo_stream response" do
          subject
          expect(response).to have_http_status(:ok)
        end

        it "persists the grade via ExamGraderService" do
          expect(Assessment::ExamGraderService).to receive(:set_grade).with(
            instance_of(Assessment::Participation), "1.7", grader, "oral exam"
          ).and_call_original

          subject
        end

        it "does not call TalkGraderService" do
          expect(Assessment::TalkGraderService).not_to receive(:set_grade)
          subject
        end

        it "renders the replaced participation row" do
          subject
          expect(response.body).to include("grading-participation-row-#{exam_participation.id}")
        end

        it "sets a success flash notice" do
          subject
          expect(flash.now[:notice]).to eq(I18n.t("assessment.grades_updated"))
        end
      end

      context "when ExamGraderService raises ExamGraderError" do
        before do
          allow(Assessment::ExamGraderService).to receive(:set_grade)
            .and_raise(Assessment::ExamGraderService::ExamGraderError, "not open for grading")
        end

        it "rescues the error instead of raising a 500" do
          expect { subject }.not_to raise_error
        end

        it "responds with the alert flash" do
          subject
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("not open for grading")
        end
      end

      context "when GradeEntryService raises GradeEntryError" do
        before do
          allow(Assessment::ExamGraderService).to receive(:set_grade)
            .and_raise(Assessment::GradeEntryService::GradeEntryError, "invalid entry")
        end

        it "responds with the alert flash" do
          subject
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("invalid entry")
        end
      end

      context "when the current user cannot enter grades in the exam's lecture" do
        before { allow_any_instance_of(User).to receive(:can_enter_grades_in?).and_return(false) }

        it "redirects to root" do
          subject
          expect(response).to redirect_to(root_path)
        end

        it "does not persist a grade" do
          subject
          expect(exam_participation.reload.grade_numeric).to be_nil
        end
      end

      context "when participation_id does not exist" do
        subject do
          patch grade_participation_path(participation_id: -1),
                params: { grade: "1.7" },
                headers: turbo_stream_headers
        end

        it "responds with the invalid params alert" do
          subject
          expect(response.body).to include(
            I18n.t("assessment.errors.invalid_request_params")
          )
        end
      end
    end

    describe "PATCH #refresh (exam)" do
      subject do
        patch refresh_grade_participation_path(exam_participation),
              headers: turbo_stream_headers
      end

      it "returns a successful turbo_stream response" do
        subject
        expect(response).to have_http_status(:ok)
      end

      it "re-renders the participation row" do
        subject
        expect(response.body).to include("grading-participation-row-#{exam_participation.id}")
      end
    end
  end
end
