require "rails_helper"

RSpec.describe("Assessment::Grades", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:tutor) { create(:confirmed_user) }
  let(:speaker) { create(:confirmed_user) }

  let(:seminar) { create(:lecture, :released_for_all, sort: "seminar", teacher: teacher) }
  let!(:talk) { create(:talk, lecture: seminar, dates: [1.week.from_now]) }
  let(:assessment) { talk.reload.assessment }

  before do
    Flipper.enable(:assessment_grading)
    Flipper.enable(:registration_campaigns)
    Flipper.enable(:roster_maintenance)
    create(:speaker_talk_join, talk: talk, speaker: speaker)
    talk.reload
  end

  after do
    Flipper.disable(:assessment_grading)
    Flipper.disable(:registration_campaigns)
    Flipper.disable(:roster_maintenance)
  end

  # PATCH grade_talk_user
  describe "PATCH /talks/:talk_id/grade_user/:user_id" do
    context "as teacher" do
      before { sign_in teacher }

      it "calls TalkGraderService.set_grade" do
        expect(Assessment::TalkGraderService).to receive(:set_grade)
        patch grade_talk_user_path(talk, speaker),
              params: { grade: "1.0", comment: "well done" },
              as: :turbo_stream
      end

      it "returns turbo_stream success" do
        patch grade_talk_user_path(talk, speaker),
              params: { grade: "1.0", comment: "well done" },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "creates a participation when none exists" do
        expect do
          patch(grade_talk_user_path(talk, speaker),
                params: { grade: "1.0" },
                as: :turbo_stream)
        end.to change(Assessment::Participation, :count).by(1)
      end

      it "persists the grade on the participation" do
        patch grade_talk_user_path(talk, speaker),
              params: { grade: "1.3" },
              as: :turbo_stream

        participation = Assessment::Participation.find_by(assessment: assessment, user: speaker)
        expect(participation.grade_numeric).to eq(1.3)
      end

      it "reuses an existing participation instead of creating a duplicate" do
        create(:assessment_participation, assessment: assessment, user: speaker)

        expect do
          patch(grade_talk_user_path(talk, speaker),
                params: { grade: "1.0" },
                as: :turbo_stream)
        end.not_to change(Assessment::Participation, :count)
      end

      context "when talk is not found" do
        it "responds with turbo_stream alert" do
          patch grade_talk_user_path(999_999, speaker),
                params: { grade: "1.0" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(I18n.t("assessment.grades.talk_not_found"))
        end
      end

      context "when user is not found" do
        it "responds with turbo_stream alert" do
          patch grade_talk_user_path(talk, 999_999),
                params: { grade: "1.0" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(I18n.t("assessment.grades.user_not_found"))
        end
      end

      context "when user is not a speaker on the talk" do
        let(:non_speaker) { create(:confirmed_user) }

        it "responds with turbo_stream alert" do
          patch grade_talk_user_path(talk, non_speaker),
                params: { grade: "1.0" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(I18n.t("assessment.grades.user_not_speaker"))
        end
      end

      context "when talk has no assessment" do
        let!(:bare_talk) { create(:talk, lecture: seminar, dates: [1.week.from_now]) }

        before do
          create(:speaker_talk_join, talk: bare_talk, speaker: speaker)
          bare_talk.assessment&.destroy
          bare_talk.reload
        end

        it "responds with turbo_stream alert" do
          patch grade_talk_user_path(bare_talk, speaker),
                params: { grade: "1.0" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(I18n.t("assessment.grades.talk_missing_assessment"))
        end
      end

      context "with an invalid grade" do
        it "responds with turbo_stream alert and does not persist" do
          expect do
            patch(grade_talk_user_path(talk, speaker),
                  params: { grade: "6.0" },
                  as: :turbo_stream)
          end.not_to change(Assessment::Participation, :count)

          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
      end
    end
  end

  # PATCH refresh_grade_talk_user
  describe "PATCH /talks/:talk_id/refresh_grade_user/:user_id" do
    before { sign_in teacher }

    it "returns turbo_stream success" do
      patch refresh_grade_talk_user_path(talk, speaker),
            as: :turbo_stream
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
    end

    it "does not create a participation" do
      expect do
        patch(refresh_grade_talk_user_path(talk, speaker),
              as: :turbo_stream)
      end.not_to change(Assessment::Participation, :count)
    end

    context "when talk is not found" do
      it "responds with turbo_stream alert" do
        patch refresh_grade_talk_user_path(999_999, speaker),
              as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include(I18n.t("assessment.grades.talk_not_found"))
      end
    end

    context "when user is not found" do
      it "responds with turbo_stream alert" do
        patch refresh_grade_talk_user_path(talk, 999_999),
              as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include(I18n.t("assessment.grades.user_not_found"))
      end
    end
  end

  # Authorization
  describe "authorization" do
    context "when user is not signed in" do
      it "redirects grade_talk_user to sign in" do
        patch grade_talk_user_path(talk, speaker),
              params: { grade: "1.0" },
              as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when user cannot grade (student)" do
      before { sign_in speaker }

      it "redirects grade_talk_user to root" do
        patch grade_talk_user_path(talk, speaker),
              params: { grade: "1.0" },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end

    context "when user is the lecture teacher" do
      before { sign_in teacher }

      it "allows grade_talk_user" do
        patch grade_talk_user_path(talk, speaker),
              params: { grade: "1.0" },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is a teacher but not this lecture's teacher" do
      let(:other_teacher) { create(:confirmed_user) }

      before { sign_in other_teacher }

      it "redirects grade_talk_user to root" do
        patch grade_talk_user_path(talk, speaker),
              params: { grade: "1.0" },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
