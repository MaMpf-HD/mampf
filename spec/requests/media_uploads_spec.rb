require "rails_helper"

RSpec.describe("MediaUploads", type: :request) do
  let(:user) { create(:confirmed_user, admin: true, locale: "en") }
  let(:scanner) { instance_double(ClamavScanner) }

  before do
    sign_in user
    allow(MalwareScanGate).to receive(:scanner).and_return(scanner)
  end

  it "rejects infected pdf uploads before metadata extraction runs" do
    allow(scanner).to receive(:scan)
      .and_return(UploadScanResult.infected("Eicar-Signature"))

    upload = Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "manuscript.pdf"),
                                          "application/pdf")

    post "/pdfs/upload", params: { file: upload }

    expect(response.status).to eq(422)
    expect(response.body).to include(
      I18n.t("submission.upload_failure_malware", locale: user.locale)
    )
  end

  it "adds clean scan metadata to profile image uploads" do
    allow(scanner).to receive(:scan).and_return(UploadScanResult.clean)

    upload = Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "image.png"),
                                          "image/png")

    post "/profile_image/upload", params: { file: upload }

    expect(response).to have_http_status(:ok)
    data = JSON.parse(response.body)
    expect(data.dig("metadata", "malware_scan", "status")).to eq("clean")
  end

  it "returns a scanner unavailable message for media uploads" do
    allow(scanner).to receive(:scan)
      .and_return(UploadScanResult.unavailable("Connection refused"))

    upload = Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "manuscript.pdf"),
                                          "application/pdf")

    post "/pdfs/upload", params: { file: upload }

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to include(
      I18n.t("submission.upload_failure_scanner_unavailable",
             locale: user.locale)
    )
  end

  it "rejects infected geogebra uploads before archive inspection runs" do
    allow(scanner).to receive(:scan)
      .and_return(UploadScanResult.infected("Eicar-Signature"))

    upload = Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "manuscript.pdf"),
                                          "application/zip")

    post "/ggbs/upload", params: { file: upload }

    expect(response.status).to eq(422)
    expect(response.body).to include(
      I18n.t("submission.upload_failure_malware", locale: user.locale)
    )
  end
end
