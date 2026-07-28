require "rails_helper"

RSpec.describe("Submissions", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:assignment) { create(:assignment, lecture: lecture, accepted_file_type: ".pdf") }
  let(:tutorial) { create(:tutorial, lecture: lecture) }

  before do
    sign_in user
  end

  describe "GET /submissions/:id/show_manuscript" do
    let(:submission) do
      create(:submission, :with_manuscript, assignment: assignment,
                                            tutorial: tutorial).tap do |record|
        record.users << user
      end
    end

    it "sanitizes the manuscript filename from uploaded metadata" do
      allow_any_instance_of(SubmissionUploader::UploadedFile).to receive(:metadata)
        .and_wrap_original do |original, *args|
          original.call(*args).merge("filename" => "../evil\r\nname.pdf")
        end

      get show_submission_manuscript_path(submission)

      content_disposition = response.headers["Content-Disposition"]

      expect(response).to have_http_status(:ok)
      expect(content_disposition).to include("inline")
      expect(content_disposition).to include("evil")
      expect(content_disposition).to include("name.pdf")
      expect(content_disposition).not_to include("../")
      expect(content_disposition).not_to match(/[\r\n]/)
    end

    it "serves a content-sniffed text/html manuscript as text/plain (FU-01)" do
      submission.reload # create with real application/pdf metadata before stubbing

      allow_any_instance_of(SubmissionUploader::UploadedFile).to receive(:metadata)
        .and_wrap_original do |original, *args|
          original.call(*args).merge("mime_type" => "text/html")
        end

      get show_submission_manuscript_path(submission)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
    end

    it "still serves a PDF manuscript inline as application/pdf" do
      get show_submission_manuscript_path(submission)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("inline")
    end
  end

  describe "GET /submissions/:id/show_correction" do
    let(:submission) do
      create(:submission, :with_correction, assignment: assignment,
                                            tutorial: tutorial).tap do |record|
        record.users << user
      end
    end

    it "sanitizes the correction filename from uploaded metadata" do
      allow_any_instance_of(CorrectionUploader::UploadedFile).to receive(:metadata)
        .and_wrap_original do |original, *args|
          original.call(*args).merge("filename" => "../evil\r\nname.pdf")
        end

      get show_correction_path(submission, download: true)

      content_disposition = response.headers["Content-Disposition"]

      expect(response).to have_http_status(:ok)
      expect(content_disposition).to include("attachment")
      expect(content_disposition).to include("evil")
      expect(content_disposition).to include("name.pdf")
      expect(content_disposition).not_to include("../")
      expect(content_disposition).not_to match(/[\r\n]/)
    end
  end

  describe "POST /submissions" do
    def create_params
      # the create form always sends a (possibly empty) manuscript field
      { submission: { assignment_id: assignment.id, tutorial_id: tutorial.id,
                      manuscript: "" } }
    end

    def create_params_no_tutorial
      # the create form always sends a (possibly empty) manuscript field
      { submission: { assignment_id: assignment.id,
                      manuscript: "" } }
    end

    it "lets a student enrolled in the lecture create a submission" do
      user.lectures << lecture
      expect { post(submissions_path(format: :js), params: create_params) }
        .to change(Submission, :count).by(1)
    end

    it "does not let a user not enrolled in the lecture create a submission" do
      expect { post(submissions_path(format: :js), params: create_params) }
        .not_to change(Submission, :count)
    end

    context "when feature flag enabled" do
      let(:other_tutorial) { create(:tutorial, lecture: lecture) }
      before do
        Flipper.enable(:roster_maintenance)
        Flipper.enable(:registration_campaigns)
      end

      after do
        Flipper.disable(:roster_maintenance)
        Flipper.disable(:registration_campaigns)
      end
      context "roster-eligible lecture, student not enrolled" do
        before do
          other_user = create(:confirmed_user)
          create(:lecture_membership, lecture: lecture, user: user)
          create(:tutorial_membership, tutorial: other_tutorial, user: other_user)
        end

        it "does not create a submission and redirects to lecture submissions with an alert" do
          user.lectures << lecture
          expect { post(submissions_path(format: :js), params: create_params) }
            .not_to change(Submission, :count)

          expect(response).to redirect_to(start_path)
          follow_redirect!
          expect(flash[:alert]).to eq(
            I18n.t("submission.tutorial_not_assigned", lecture: lecture.title)
          )
        end
      end

      context "roster-eligible lecture, student enrolled" do
        before do
          create(:lecture_membership, lecture: lecture, user: user)
          create(:tutorial_membership, tutorial: tutorial, user: user)
        end

        it "creates the submission on the student's rostered tutorial" do
          user.lectures << lecture
          expect { post(submissions_path(format: :js), params: create_params_no_tutorial) }
            .to change(Submission, :count).by(1)

          expect(Submission.last.tutorial).to eq(tutorial)
        end
      end
    end
  end

  describe "PATCH /submissions/:id" do
    let(:submission) do
      create(:submission, assignment: assignment, tutorial: tutorial, users: [user])
    end

    def update_params(tutorial_id:)
      { submission: { tutorial_id: tutorial_id, manuscript: "" } }
    end

    context "when feature flag enabled" do
      let(:other_tutorial) { create(:tutorial, lecture: lecture) }

      before do
        Flipper.enable(:roster_maintenance)
        Flipper.enable(:registration_campaigns)
      end
      after do
        Flipper.disable(:roster_maintenance)
        Flipper.disable(:registration_campaigns)
      end

      context "roster-eligible lecture, student not enrolled" do
        before do
          other_user = create(:confirmed_user)
          create(:lecture_membership, lecture: lecture, user: user)
          create(:tutorial_membership, tutorial: other_tutorial, user: other_user)
        end

        it "does not update the submission and redirects to lecture submissions with an alert" do
          patch submission_path(submission, format: :js),
                params: update_params(tutorial_id: other_tutorial.id)

          expect(response).to redirect_to(start_path)
          follow_redirect!
          expect(flash[:alert]).to eq(
            I18n.t("submission.tutorial_not_assigned", lecture: lecture.title)
          )
        end
      end

      context "roster-eligible lecture, student enrolled" do
        before do
          create(:lecture_membership, lecture: lecture, user: user)
          create(:tutorial_membership, tutorial: tutorial, user: user)
        end

        it "updates the submission, keeping it on the student's rostered tutorial" do
          patch submission_path(submission, format: :js),
                params: update_params(tutorial_id: other_tutorial.id)

          expect(submission.reload.tutorial).to eq(tutorial)
        end
      end
    end
  end
end
