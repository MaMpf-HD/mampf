require "rails_helper"

RSpec.describe(Assessment::GradesController, type: :request) do
  let(:teacher) { FactoryBot.create(:confirmed_user) }
  let(:seminar) do
    FactoryBot.create(:lecture, :released_for_all, sort: "seminar", teacher: teacher)
  end
  let(:talk) { FactoryBot.create(:talk, lecture: seminar, dates: [1.week.from_now]) }
  let(:speaker) { FactoryBot.create(:confirmed_user) }
  let(:assessment) { talk.reload.assessment }
  let(:grader) { FactoryBot.create(:confirmed_user) }
  let!(:participation) do
    FactoryBot.create(:assessment_participation, assessment: assessment, user: speaker)
  end
  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  before do
    FactoryBot.create(:speaker_talk_join, talk: talk, speaker: speaker)
    allow_any_instance_of(User).to receive(:can_grade_in_scope?).and_return(true)
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

    context "when the current user is not authorized to grade" do
      before do
        allow_any_instance_of(AssessmentAbility).to receive(:can?).and_return(false)
      end

      it "does not raise an unhandled error" do
        expect { subject }.not_to raise_error
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
