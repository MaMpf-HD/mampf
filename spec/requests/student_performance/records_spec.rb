require "rails_helper"
require "sidekiq/testing"

RSpec.describe("StudentPerformance::Records", type: :request) do
  let(:lecture) { FactoryBot.create(:lecture, locale: I18n.default_locale) }
  let(:editor) { FactoryBot.create(:confirmed_user) }
  let(:student) { FactoryBot.create(:confirmed_user) }

  before do
    Flipper.enable(:student_performance)
    FactoryBot.create(:editable_user_join, user: editor, editable: lecture)
    editor.reload
    lecture.reload
    Sidekiq::Testing.fake!
  end

  after do
    Flipper.disable(:student_performance)
    Sidekiq::Worker.clear_all
  end

  describe "GET /lectures/:lecture_id/performance/records" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get lecture_student_performance_records_path(lecture)
        expect(response).to have_http_status(:success)
      end

      it "includes records for the lecture" do
        user = FactoryBot.create(:confirmed_user)
        FactoryBot.create(:student_performance_record,
                          lecture: lecture, user: user)
        get lecture_student_performance_records_path(lecture)
        expect(response.body).to include(user.tutorial_name)
      end

      it "does not include records from other lectures" do
        other_user = FactoryBot.create(:confirmed_user)
        other_lecture = FactoryBot.create(:lecture)
        FactoryBot.create(:student_performance_record,
                          lecture: other_lecture, user: other_user)
        get lecture_student_performance_records_path(lecture)
        expect(response.body).not_to include(other_user.tutorial_name)
      end

      context "with achievements" do
        before { Flipper.enable(:assessment_grading) }

        after { Flipper.disable(:assessment_grading) }

        it "renders achievement columns when achievements exist" do
          user = FactoryBot.create(:confirmed_user)
          FactoryBot.create(:lecture_membership,
                            lecture: lecture, user: user)
          achievement = FactoryBot.create(:achievement, :boolean,
                                          lecture: lecture)
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: user,
                            achievements_met_ids: [achievement.id])

          get lecture_student_performance_records_path(lecture)
          expect(response.body).to include(achievement.title)
          expect(response.body).to include("bi-check-circle-fill")
        end

        it "renders not-met icon for unmet achievements" do
          user = FactoryBot.create(:confirmed_user)
          FactoryBot.create(:lecture_membership,
                            lecture: lecture, user: user)
          achievement = FactoryBot.create(:achievement, :boolean,
                                          lecture: lecture)
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: user,
                            achievements_met_ids: [])

          get lecture_student_performance_records_path(lecture)
          expect(response.body).to include(achievement.title)
          expect(response.body).to include("bi-x-circle")
        end
      end

      context "with tutorial filter" do
        let(:tutorial) do
          FactoryBot.create(:tutorial, lecture: lecture)
        end
        let(:member) { FactoryBot.create(:confirmed_user) }
        let(:non_member) { FactoryBot.create(:confirmed_user) }

        before do
          FactoryBot.create(:tutorial_membership,
                            tutorial: tutorial, user: member)
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: member)
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: non_member)
        end

        it "filters records by tutorial_id" do
          get lecture_student_performance_records_path(
            lecture, tutorial_id: tutorial.id
          )
          expect(response.body).to include(member.tutorial_name)
          expect(response.body).not_to include(non_member.tutorial_name)
        end
      end

      context "with pagination" do
        before do
          26.times do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture)
          end
        end

        it "paginates results" do
          get lecture_student_performance_records_path(lecture)
          expect(response).to have_http_status(:success)
          pagy = controller.instance_variable_get(:@pagy)
          expect(pagy).to be_present
          expect(pagy.count).to eq(26)
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get lecture_student_performance_records_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when feature flag is disabled" do
      before do
        Flipper.disable(:student_performance)
        sign_in editor
      end

      it "falls through to catch-all and redirects" do
        get lecture_student_performance_records_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when lecture does not exist" do
      before { sign_in editor }

      it "redirects to root" do
        get lecture_student_performance_records_path(lecture_id: "nonexistent")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /lectures/:lecture_id/performance/records/:id" do
    let!(:record) do
      FactoryBot.create(:student_performance_record, lecture: lecture)
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get lecture_student_performance_record_path(lecture, record)
        expect(response).to have_http_status(:success)
      end

      it "scopes record to the lecture" do
        other_lecture = FactoryBot.create(:lecture)
        other_record = FactoryBot.create(:student_performance_record,
                                         lecture: other_lecture)
        get lecture_student_performance_record_path(lecture, other_record)
        expect(response).to redirect_to(
          lecture_student_performance_records_path(lecture)
        )
      end

      it "redirects when record does not exist" do
        get lecture_student_performance_record_path(lecture, id: "nonexistent")
        expect(response).to redirect_to(
          lecture_student_performance_records_path(lecture)
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get lecture_student_performance_record_path(lecture, record)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /lectures/:lecture_id/performance/records/recompute" do
    context "as an editor" do
      before { sign_in editor }

      it "enqueues a job for all students" do
        expect do
          post(recompute_lecture_student_performance_records_path(lecture))
        end.to change(PerformanceRecordUpdateJob.jobs, :size).by(1)

        job = PerformanceRecordUpdateJob.jobs.last
        expect(job["args"]).to eq([lecture.id, nil])
      end

      it "computes inline for a single student and redirects" do
        user = FactoryBot.create(:confirmed_user)
        FactoryBot.create(:lecture_membership, user: user, lecture: lecture)

        expect do
          post(recompute_lecture_student_performance_records_path(lecture),
               params: { user_id: user.id })
        end.not_to change(PerformanceRecordUpdateJob.jobs, :size)

        record = lecture.student_performance_records
                        .find_by(user_id: user.id)
        expect(response).to redirect_to(
          lecture_student_performance_record_path(lecture, record)
        )
      end

      it "redirects with alert when user_id is not a lecture member" do
        outsider = FactoryBot.create(:confirmed_user)

        expect do
          post(recompute_lecture_student_performance_records_path(lecture),
               params: { user_id: outsider.id })
        end.not_to change(PerformanceRecordUpdateJob.jobs, :size)

        expect(response).to redirect_to(
          lecture_student_performance_records_path(lecture)
        )
        expect(flash[:alert]).to eq(
          I18n.t("student_performance.errors.no_member")
        )
      end

      it "responds with turbo_stream flash for bulk recompute" do
        post recompute_lecture_student_performance_records_path(lecture),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq(
          "text/vnd.turbo-stream.html"
        )
        expect(response.headers["X-Recompute-Queued"]).to eq("1")
        expect(response.headers["X-Recompute-Since"]).to be_present
      end

      it "redirects for html format" do
        post recompute_lecture_student_performance_records_path(lecture)
        expect(response).to redirect_to(
          lecture_student_performance_records_path(lecture)
        )
      end

      it "throttles repeated bulk recompute requests" do
        post recompute_lecture_student_performance_records_path(lecture)
        expect(PerformanceRecordUpdateJob.jobs.size).to eq(1)

        post recompute_lecture_student_performance_records_path(lecture)
        expect(PerformanceRecordUpdateJob.jobs.size).to eq(1)
        expect(response.headers["X-Recompute-Queued"]).to eq("0")
        expect(flash[:alert]).to eq(
          I18n.t("student_performance.records.recompute.throttled")
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        post recompute_lecture_student_performance_records_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /lectures/:lecture_id/performance/records/recompute_status" do
    context "as an editor" do
      before { sign_in editor }

      it "returns done: true when lecture has no members" do
        get recompute_status_lecture_student_performance_records_path(lecture),
            params: { since: 1.minute.ago.iso8601 }
        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body["done"]).to be(true)
      end

      it "returns done: false when lecture has members but no records" do
        member = FactoryBot.create(:confirmed_user)
        FactoryBot.create(:lecture_membership, lecture: lecture, user: member)

        get recompute_status_lecture_student_performance_records_path(lecture),
            params: { since: 1.minute.ago.iso8601 }
        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body["done"]).to be(false)
      end

      it "returns done: true when all records are newer than since" do
        FactoryBot.create(:student_performance_record,
                          lecture: lecture,
                          computed_at: Time.current)

        get recompute_status_lecture_student_performance_records_path(lecture),
            params: { since: 1.minute.ago.iso8601 }
        body = response.parsed_body
        expect(body["done"]).to be(true)
      end

      it "returns done: false when some records are older than since" do
        user = FactoryBot.create(:confirmed_user)
        FactoryBot.create(:lecture_membership, lecture: lecture, user: user)
        FactoryBot.create(:student_performance_record,
                          lecture: lecture,
                          user: user,
                          computed_at: 5.minutes.ago)

        get recompute_status_lecture_student_performance_records_path(lecture),
            params: { since: 1.minute.ago.iso8601 }
        body = response.parsed_body
        expect(body["done"]).to be(false)
      end

      it "returns done: false when since is missing" do
        get recompute_status_lecture_student_performance_records_path(lecture)
        body = response.parsed_body
        expect(body["done"]).to be(false)
      end

      it "returns done: false when since is malformed" do
        get recompute_status_lecture_student_performance_records_path(lecture),
            params: { since: "not-a-date" }
        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body["done"]).to be(false)
      end

      it "returns done: false when a record has null computed_at" do
        user_one = FactoryBot.create(:confirmed_user)
        user_two = FactoryBot.create(:confirmed_user)
        FactoryBot.create(:lecture_membership,
                          lecture: lecture,
                          user: user_one)
        FactoryBot.create(:lecture_membership,
                          lecture: lecture,
                          user: user_two)
        FactoryBot.create(:student_performance_record,
                          lecture: lecture,
                          user: user_one,
                          computed_at: Time.current)
        FactoryBot.create(:student_performance_record,
                          lecture: lecture,
                          user: user_two,
                          computed_at: nil)

        get recompute_status_lecture_student_performance_records_path(lecture),
            params: { since: 1.minute.ago.iso8601 }
        body = response.parsed_body
        expect(body["done"]).to be(false)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get recompute_status_lecture_student_performance_records_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
