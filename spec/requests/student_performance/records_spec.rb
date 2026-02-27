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
        expect(response.body).to include(user.email)
      end

      it "does not include records from other lectures" do
        other_user = FactoryBot.create(:confirmed_user)
        other_lecture = FactoryBot.create(:lecture)
        FactoryBot.create(:student_performance_record,
                          lecture: other_lecture, user: other_user)
        get lecture_student_performance_records_path(lecture)
        expect(response.body).not_to include(other_user.email)
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
          expect(response.body).to include(member.email)
          expect(response.body).not_to include(non_member.email)
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
        expect(job["args"]).to eq([lecture.id])
      end

      it "enqueues a job for a single student" do
        user = FactoryBot.create(:confirmed_user)

        expect do
          post(recompute_lecture_student_performance_records_path(
                 lecture, params: { user_id: user.id }
               ))
        end.to change(PerformanceRecordUpdateJob.jobs, :size).by(1)

        job = PerformanceRecordUpdateJob.jobs.last
        expect(job["args"]).to eq([lecture.id, user.id])
      end

      it "responds with turbo_stream flash" do
        post recompute_lecture_student_performance_records_path(lecture),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq(
          "text/vnd.turbo-stream.html"
        )
      end

      it "redirects for html format" do
        post recompute_lecture_student_performance_records_path(lecture)
        expect(response).to redirect_to(
          lecture_student_performance_records_path(lecture)
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
end
