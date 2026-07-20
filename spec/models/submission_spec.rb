require "rails_helper"

RSpec.describe(Submission, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:valid_submission)).to be_valid
  end

  # test validations

  it "is invalid without an assignment" do
    expect(FactoryBot.build(:valid_submission, assignment: nil)).to be_invalid
  end

  it "is invalid without a tutorial" do
    expect(FactoryBot.build(:valid_submission, tutorial: nil)).to be_invalid
  end

  it "is invalid if lecture does not match" do
    submission = FactoryBot.build(:valid_submission)
    submission.assignment.lecture = FactoryBot.build(:lecture)
    expect(submission).to be_invalid
  end

  # test traits

  describe "with assignment" do
    it "has an assignment" do
      submission = FactoryBot.build(:valid_submission, :with_assignment)
      expect(submission.assignment).to be_kind_of(Assignment)
    end
  end

  describe "with tutorial" do
    it "has a tutorial" do
      submission = FactoryBot.build(:valid_submission, :with_tutorial)
      expect(submission.tutorial).to be_kind_of(Tutorial)
    end
  end

  describe "with users" do
    it "has two users" do
      submission = FactoryBot.build(:valid_submission, :with_users)
      expect(submission.users.size).to eq(2)
    end
    it "has the correct number of users when users_count parameter is used" do
      submission = FactoryBot.build(:valid_submission, :with_users,
                                    users_count: 4)
      expect(submission.users.size).to eq(4)
    end
  end

  describe "with manuscript" do
    it "has a manuscript" do
      submission = FactoryBot.build(:valid_submission, :with_manuscript)
      expect(submission.manuscript)
        .to be_kind_of(SubmissionUploader::UploadedFile)
    end
  end

  describe "with correction" do
    it "has a correction" do
      submission = FactoryBot.build(:valid_submission, :with_correction)
      expect(submission.correction)
        .to be_kind_of(CorrectionUploader::UploadedFile)
    end

    it "rejects forged clean-scan metadata on cached corrections" do
      cached_upload = CorrectionUploader.upload(
        File.open(File.join(SPEC_FILES, "manuscript.pdf"), "rb"),
        :submission_cache
      )
      submission = FactoryBot.build(:valid_submission)
      forged_data = cached_upload.data.deep_dup
      forged_data["metadata"]["malware_scan"] = { "status" => "clean" }

      submission.correction = forged_data.to_json

      expect(submission).not_to be_valid
      expect(submission.errors[:correction]).to include(
        I18n.t("submission.upload_failure_scan_required", locale: I18n.locale)
      )
    ensure
      cached_upload&.delete
    end

    it "rejects direct store-keyed correction assignments" do
      stored_upload = CorrectionUploader.upload(
        File.open(File.join(SPEC_FILES, "manuscript.pdf"), "rb"),
        :submission_store
      )
      submission = FactoryBot.build(:valid_submission)

      expect { submission.correction = stored_upload.to_json }
        .to raise_error(Shrine::Error, /expected cached file/)
    ensure
      stored_upload&.delete
    end
  end

  describe "#check_file_properties_any" do
    let(:submission) { FactoryBot.build(:valid_submission) }

    it "validates a manuscript's type with SubmissionUploader, not CorrectionUploader" do
      # ".tar.gz" is accepted by SubmissionUploader (Assignment.accepted_file_types)
      # but not by CorrectionUploader, which only sees ".gz".
      meta = { "size" => 1024, "filename" => "solution.tar.gz",
               "mime_type" => "application/gzip" }
      correction_reject = I18n.t("submission.wrong_file_type",
                                 file_type: ".gz",
                                 accepted_file_type:
                                   CorrectionUploader.accepted_extension_list)

      errors = submission.send(:check_file_properties_any, meta, :submission)
                         .fetch(:submission, [])

      expect(errors).not_to include(correction_reject)
    end

    it "accepts corrections up to CorrectionUploader::MAX_SIZE" do
      meta = { "size" => 20 * 1024 * 1024, "filename" => "fix.pdf",
               "mime_type" => "application/pdf" }
      old_cap = I18n.t("submission.manuscript_size_too_big", max_size: "15 MB")
      new_cap = I18n.t("submission.manuscript_size_too_big",
                       max_size: "#{CorrectionUploader::MAX_SIZE / (1024 * 1024)} MB")

      errors = submission.send(:check_file_properties_any, meta, :correction)
                         .fetch(:correction, [])

      expect(errors).not_to include(old_cap)
      expect(errors).not_to include(new_cap)
    end

    it "rejects corrections above CorrectionUploader::MAX_SIZE" do
      meta = { "size" => CorrectionUploader::MAX_SIZE + 1, "filename" => "fix.pdf",
               "mime_type" => "application/pdf" }
      cap = I18n.t("submission.manuscript_size_too_big",
                   max_size: "#{CorrectionUploader::MAX_SIZE / (1024 * 1024)} MB")

      errors = submission.send(:check_file_properties_any, meta, :correction)
                         .fetch(:correction, [])

      expect(errors).to include(cap)
    end
  end

  describe ".bulk_corrections!" do
    let(:lecture) { create(:lecture) }
    let(:assignment) { create(:assignment, lecture: lecture) }
    let(:tutorial) { create(:tutorial, lecture: lecture) }
    let!(:in_scope) do
      create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial)
    end
    # a proper submission in a different tutorial+assignment of the same lecture
    let!(:foreign) do
      create(:submission, :with_manuscript,
             assignment: create(:assignment, lecture: lecture),
             tutorial: create(:tutorial, lecture: lecture))
    end

    it "only touches submissions in the given tutorial+assignment" do
      foreign_file = "correction-ID-#{foreign.id}.pdf"
      in_scope_file = "correction-ID-#{in_scope.id}.pdf"

      report = Submission.bulk_corrections!(
        tutorial, assignment,
        [{ "metadata" => { "filename" => foreign_file } },
         { "metadata" => { "filename" => in_scope_file } }]
      )

      # the foreign submission is out of scope: rejected as an invalid id, untouched
      expect(report[:invalid_id]).to include(foreign_file)
      expect(foreign.reload.correction).to be_blank
      # the in-scope submission is found (not rejected as an unknown id)
      expect(report[:invalid_id]).not_to include(in_scope_file)
    end
  end
end
