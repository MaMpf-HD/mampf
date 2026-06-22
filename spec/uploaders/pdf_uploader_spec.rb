require "rails_helper"

RSpec.describe(PdfUploader) do
  describe "metadata extraction" do
    it "extracts page count and mampf-sty version from an uploaded PDF" do
      uploader = described_class.new(:store)
      file = Tempfile.new(["manuscript", ".pdf"])
      file.binmode
      file.write(File.binread("#{SPEC_FILES}/manuscript.pdf"))
      file.rewind

      allow(uploader).to receive(:read_mampf_structure)
        .and_return("MaMpf-Version|1.2.3\n")

      metadata = uploader.send(:extract_metadata, file, action: :upload)

      expect(metadata["pages"]).to be_a(Integer)
      expect(metadata["pages"]).to be_positive
      expect(metadata["version"]).to eq("1.2.3")
    ensure
      file.close!
    end

    it "still returns page count when structure.mampf is absent" do
      uploader = described_class.new(:store)
      file = Tempfile.new(["manuscript", ".pdf"])
      file.binmode
      file.write(File.binread("#{SPEC_FILES}/manuscript.pdf"))
      file.rewind

      allow(uploader).to receive(:read_mampf_structure).and_return(nil)

      metadata = uploader.send(:extract_metadata, file, action: :upload)

      expect(metadata["pages"]).to be_a(Integer)
      expect(metadata["pages"]).to be_positive
      expect(metadata["bookmarks"]).to eq([])
      expect(metadata["destinations"]).to eq([])
    ensure
      file.close!
    end

    it "skips malformed MaMpf-Label rows" do
      uploader = described_class.new(:store)
      file = Tempfile.new(["manuscript", ".pdf"])
      file.binmode
      file.write(File.binread("#{SPEC_FILES}/manuscript.pdf"))
      file.rewind

      allow(uploader).to receive(:read_mampf_structure).and_return(
        "MaMpf-Label|broken\n" \
        "MaMpf-Label|dest|Sort|1.1|Desc|1|1.1|1.1.0|7\n"
      )

      metadata = uploader.send(:extract_metadata, file, action: :upload)

      expect(metadata["bookmarks"].size).to eq(1)
      expect(metadata["bookmarks"].first["destination"]).to eq("dest")
      expect(metadata["bookmarks"].first["counter"]).to eq(0)
    ensure
      file.close!
    end
  end

  describe "qpdf extraction" do
    it "returns nil when qpdf exceeds the timeout" do
      uploader = described_class.new(:store)

      allow(Process).to receive(:spawn).and_return(1234)
      allow(Timeout).to receive(:timeout).with(PdfUploader::TOOL_TIMEOUT)
                                         .and_raise(Timeout::Error)
      expect(uploader).to receive(:terminate_process_group).with(1234)

      Dir.mktmpdir do |dir|
        result = uploader.send(:read_mampf_structure, "input.pdf", dir)
        expect(result).to be_nil
      end
    end

    it "returns nil when qpdf cannot be spawned" do
      uploader = described_class.new(:store)

      allow(Process).to receive(:spawn).and_raise(Errno::ENOENT)

      Dir.mktmpdir do |dir|
        result = uploader.send(:read_mampf_structure, "input.pdf", dir)
        expect(result).to be_nil
      end
    end
  end
end
