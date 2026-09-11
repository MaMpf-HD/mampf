require "rails_helper"

RSpec.describe("SubmissionUploads", type: :request) do
  let(:user) { create(:confirmed_user, locale: "en") }
  let(:scanner) { instance_double(ClamavScanner) }
  let(:assignment) { create(:assignment, :with_lecture) }
  let(:submission) { Submission.new(assignment: assignment) }
  let(:upload) do
    Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "manuscript.pdf"),
                                 "application/pdf")
  end

  before do
    assignment.lecture.users << user
    user.reload
    sign_in user
    allow(MalwareScanGate).to receive(:scanner).and_return(scanner)
    allow(MalwareScanMetrics).to receive(:record_scan)
  end

  it "rejects infected uploads before they enter cache" do
    allow(scanner).to receive(:scan)
      .and_return(UploadScanResult.infected("Eicar-Signature"))

    post "/submissions/upload",
         params: { file: upload },
         headers: upload_intent_headers(SubmissionUploader, user: user,
                                                            target: submission)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include(
      I18n.t("submission.upload_failure_malware", locale: user.locale)
    )
  end

  it "adds clean scan metadata to cached uploads" do
    allow(scanner).to receive(:scan).and_return(UploadScanResult.clean)

    post "/submissions/upload",
         params: { file: upload },
         headers: upload_intent_headers(SubmissionUploader, user: user,
                                                            target: submission)

    expect(response).to have_http_status(:ok)
    expect(MalwareScanMetrics).to have_received(:record_scan).with(
      uploader_class: SubmissionUploader,
      storage_key: :submission_cache,
      result: have_attributes(status: :clean),
      duration_seconds: be_a(Float),
      scope: "full"
    )
    data = JSON.parse(response.body)
    expect(data.dig("metadata", "malware_scan", "status")).to eq("clean")
    expect(data.dig("metadata", "malware_scan", "scanner")).to eq("clamav")
  end

  it "adds clean scan metadata to correction uploads" do
    allow(scanner).to receive(:scan).and_return(UploadScanResult.clean)

    tutorial = create(:tutorial, :with_tutor_by_id, tutor_id: user.id,
                                                    lecture: assignment.lecture)
    tutor = user.reload
    corrected = create(:submission, assignment: assignment, tutorial: tutorial)
    sign_in tutor

    post "/corrections/upload",
         params: { file: upload },
         headers: upload_intent_headers(CorrectionUploader,
                                        user: tutor, target: corrected,
                                        action: :add_correction)

    expect(response).to have_http_status(:ok)
    data = JSON.parse(response.body)
    expect(data.dig("metadata", "malware_scan", "status")).to eq("clean")
  end

  it "returns a scanner unavailable message for submission uploads" do
    allow(scanner).to receive(:scan)
      .and_return(UploadScanResult.unavailable("Connection refused"))

    post "/submissions/upload",
         params: { file: upload },
         headers: upload_intent_headers(SubmissionUploader, user: user,
                                                            target: submission)

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to include(
      I18n.t("submission.upload_failure_scanner_unavailable",
             locale: user.locale)
    )
  end

  it "treats scan timeouts as scanner unavailable for submission uploads" do
    allow(scanner).to receive(:scan).and_return(UploadScanResult.timeout)

    post "/submissions/upload",
         params: { file: upload },
         headers: upload_intent_headers(SubmissionUploader, user: user,
                                                            target: submission)

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to include(
      I18n.t("submission.upload_failure_scanner_unavailable",
             locale: user.locale)
    )
  end

  it "uses the explicit request locale for upload error messages" do
    allow(scanner).to receive(:scan)
      .and_return(UploadScanResult.infected("Eicar-Signature"))

    post "/submissions/upload",
         params: { file: upload, locale: "de" },
         headers: upload_intent_headers(SubmissionUploader, user: user,
                                                            target: submission)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include(
      I18n.t("submission.upload_failure_malware", locale: :de)
    )
  end

  it "rejects cached uploads without clean scan metadata during assignment" do
    cached_upload = SubmissionUploader.upload(
      File.open(File.join(SPEC_FILES, "manuscript.pdf"), "rb"),
      :submission_cache
    )
    submission = build(:valid_submission)

    submission.manuscript = cached_upload.to_json

    expect(submission).not_to be_valid
    expect(submission.errors[:manuscript])
      .to include(
        I18n.t("submission.upload_failure_scan_required", locale: I18n.locale)
      )
  end

  it "rejects promotion of cached uploads without clean scan metadata" do
    cached_upload = SubmissionUploader.upload(
      File.open(File.join(SPEC_FILES, "manuscript.pdf"), "rb"),
      :submission_cache
    )
    attacher = SubmissionUploader::Attacher.from_data(cached_upload.data)

    expect { attacher.promote }
      .to raise_error(Shrine::Error,
                      "cached upload is missing clean malware scan metadata")
  ensure
    cached_upload&.delete
  end
end
