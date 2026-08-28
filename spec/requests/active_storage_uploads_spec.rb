require "rails_helper"

RSpec.describe("ActiveStorageUploads", type: :request) do
  let(:editor) do
    create(:confirmed_user, locale: "en").tap do |user|
      create(:course, :with_editor_by_id, editor_id: user.id)
      user.reload
    end
  end
  let(:scanner) { instance_double(ClamavScanner) }
  let(:content) { File.binread(File.join(SPEC_FILES, "image.png")) }
  let(:blob) do
    ActiveStorage::Blob.create_before_direct_upload!(
      filename: "image.png", byte_size: content.bytesize,
      checksum: Digest::MD5.base64digest(content), content_type: "image/png"
    )
  end

  before do
    sign_in editor
    allow(MalwareScanGate).to receive(:scanner).and_return(scanner)
  end

  def put_blob
    ActiveStorage::Current.url_options = { host: "http://www.example.com" }
    url = blob.service.url_for_direct_upload(
      blob.key, expires_in: 5.minutes, content_type: blob.content_type,
                content_length: blob.byte_size, checksum: blob.checksum
    )

    put(URI.parse(url).request_uri, params: content,
                                    headers: { "CONTENT_TYPE" => blob.content_type })
  end

  def fetch_blob
    ActiveStorage::Current.url_options = { host: "http://www.example.com" }
    url = blob.service.url(blob.key, expires_in: 5.minutes, filename: blob.filename,
                                     content_type: blob.content_type, disposition: :inline)

    get(URI.parse(url).request_uri)
  end

  it "stores a clean file and remembers the verdict" do
    allow(scanner).to receive(:scan).and_return(UploadScanResult.clean)

    put_blob

    expect(response).to have_http_status(:no_content)
    expect(blob.reload.metadata.dig("malware_scan", "status")).to eq("clean")
    expect(blob.service.exist?(blob.key)).to be(true)
  end

  it "keeps an infected file out of the store" do
    allow(scanner).to receive(:scan)
      .and_return(UploadScanResult.infected("Eicar-Signature"))

    put_blob

    expect(response).to have_http_status(:unprocessable_content)
    expect(blob.reload.metadata).not_to have_key("malware_scan")
    expect(blob.service.exist?(blob.key)).to be(false)
  end

  it "does not store anything while the scanner is unreachable" do
    allow(scanner).to receive(:scan)
      .and_return(UploadScanResult.unavailable("Connection refused"))

    put_blob

    expect(response).to have_http_status(:service_unavailable)
    expect(blob.service.exist?(blob.key)).to be(false)
  end

  describe "handing a stored file back" do
    before do
      allow(scanner).to receive(:scan).and_return(UploadScanResult.clean)
      put_blob
    end

    it "serves what was scanned" do
      fetch_blob

      expect(response).to have_http_status(:ok)
    end

    it "does not serve what carries no verdict" do
      blob.reload.update!(metadata: {})

      fetch_blob

      expect(response).to have_http_status(:not_found)
    end

    it "does not hand it out through the proxy route either" do
      blob.reload.update!(metadata: {})

      get rails_storage_proxy_path(blob)

      expect(response).to have_http_status(:not_found)
    end

    it "hands a scanned file through the proxy route" do
      get rails_storage_proxy_path(blob)

      expect(response).to have_http_status(:ok)
    end
  end

  it "assumes the disk service, and says so when that stops being true" do
    expect(ActiveStorage::Blob.service).to be_a(ActiveStorage::Service::DiskService)
  end
end
