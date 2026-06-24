require "rails_helper"

RSpec.describe("SubmissionUploads", type: :request) do
  let(:user) { create(:confirmed_user, locale: "en") }
  let(:scanner) { instance_double(ClamavScanner) }
  let(:upload) do
    Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "manuscript.pdf"),
                                 "application/pdf")
  end

  before do
    sign_in user
    allow(MalwareScanGate).to receive(:scanner).and_return(scanner)
  end

  it "rejects infected uploads before they enter cache" do
    allow(scanner).to receive(:scan)
      .and_return(UploadScanResult.infected("Eicar-Signature"))

    post "/submissions/upload", params: { file: upload }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include(
      I18n.t("submission.upload_failure_malware", locale: user.locale)
    )
  end

  it "adds clean scan metadata to cached uploads" do
    allow(scanner).to receive(:scan).and_return(UploadScanResult.clean)

    post "/submissions/upload", params: { file: upload }

    expect(response).to have_http_status(:ok)
    data = JSON.parse(response.body)
    expect(data.dig("metadata", "malware_scan", "status")).to eq("clean")
    expect(data.dig("metadata", "malware_scan", "scanner")).to eq("clamav")
  end

  it "adds clean scan metadata to correction uploads" do
    allow(scanner).to receive(:scan).and_return(UploadScanResult.clean)

    post "/corrections/upload", params: { file: upload }

    expect(response).to have_http_status(:ok)
    data = JSON.parse(response.body)
    expect(data.dig("metadata", "malware_scan", "status")).to eq("clean")
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
end