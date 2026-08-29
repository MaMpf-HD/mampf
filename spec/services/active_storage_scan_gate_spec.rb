require "rails_helper"

RSpec.describe(ActiveStorageScanGate) do
  def blob_for(metadata: {})
    ActiveStorage::Blob.create_before_direct_upload!(
      filename: "image.png", byte_size: 3, checksum: "abc",
      content_type: "image/png", metadata: metadata
    )
  end

  describe ".cleared?" do
    it "clears a file that carries a clean verdict" do
      blob = blob_for(metadata: { "malware_scan" => { "status" => "clean" } })

      expect(described_class.cleared?(blob.key)).to be(true)
    end

    it "holds back a file that carries none" do
      expect(described_class.cleared?(blob_for.key)).to be(false)
    end

    it "holds back a file nobody knows" do
      expect(described_class.cleared?("no-such-key")).to be(false)
    end

    it "clears a variant, which our own processing derived from a scanned file" do
      original = blob_for(metadata: { "malware_scan" => { "status" => "clean" } })
      variant = blob_for
      ActiveStorage::Attachment.create!(
        name: "image", blob: variant,
        record: ActiveStorage::VariantRecord.create!(blob: original,
                                                     variation_digest: "digest")
      )

      expect(described_class.cleared?(variant.key)).to be(true)
    end

    it "clears the preview of a scanned file, which hangs on the file itself" do
      original = blob_for(metadata: { "malware_scan" => { "status" => "clean" } })
      preview = blob_for
      ActiveStorage::Attachment.create!(name: "preview_image", blob: preview,
                                        record: original)

      expect(described_class.cleared?(preview.key)).to be(true)
    end

    it "holds back what was derived from a file that was never scanned" do
      unscanned = blob_for
      preview = blob_for
      ActiveStorage::Attachment.create!(name: "preview_image", blob: preview,
                                        record: unscanned)

      expect(described_class.cleared?(preview.key)).to be(false)
    end
  end

  describe ".record_verdict!" do
    it "keeps what the analyzer writes later" do
      blob = blob_for(metadata: { "width" => 10 })

      described_class.record_verdict!(blob.key, scope: "full")

      expect(blob.reload.metadata).to include("width" => 10)
      expect(blob.metadata.dig("malware_scan", "scope")).to eq("full")
    end

    it "shrugs at a key that has no blob" do
      expect { described_class.record_verdict!("no-such-key", scope: "full") }
        .not_to raise_error
    end
  end
end
