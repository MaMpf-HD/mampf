require "rails_helper"

RSpec.describe(PdfUploader) do
  describe "metadata extraction" do
    it "passes file paths to pdftk without invoking a shell" do
      uploader = described_class.new(:store)
      file = Tempfile.new(["manuscript; touch hacked", ".pdf"])
      file.binmode
      file.write(File.binread("#{SPEC_FILES}/manuscript.pdf"))
      file.rewind

      expect(uploader).to receive(:run_pdftk) do |*args|
        expect(args[0...3]).to eq([file.path, "dump_data_utf8", "output"])
        File.write(args[3], "NumberOfPages: 7\n")
        true
      end.ordered

      expect(uploader).to receive(:run_pdftk) do |*args|
        expect(args[0...3]).to eq([file.path, "unpack_files", "output"])
        expect(args[3]).to start_with(PdfUploader::UNPACK_ROOT.to_s)
        File.write(File.join(args[3], "structure.mampf"), "MaMpf-Version|1.2.3\n")
        true
      end.ordered

      metadata = uploader.send(:extract_metadata, file, action: :upload)

      expect(metadata["pages"]).to eq(7)
      expect(metadata["version"]).to eq("1.2.3")
    ensure
      file.close!
    end
  end

  describe "pdftk execution" do
    it "returns false when pdftk exceeds the timeout" do
      uploader = described_class.new(:store)

      allow(Process).to receive(:spawn).and_return(1234)
      allow(Timeout).to receive(:timeout).with(PdfUploader::PDFTK_TIMEOUT)
                                         .and_raise(Timeout::Error)
      expect(uploader).to receive(:terminate_process_group).with(1234)

      expect(uploader.send(:run_pdftk, "input.pdf", "dump_data_utf8")).to be(false)
    end
  end

  describe "unpacked structure validation" do
    it "accepts only structure.mampf" do
      uploader = described_class.new(:store)

      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "structure.mampf"), "MaMpf-Version|1.2.3\n")

        expect(uploader.send(:valid_unpacked_structure?, dir)).to be(true)
      end
    end

    it "rejects unexpected extracted files" do
      uploader = described_class.new(:store)

      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "structure.mampf"), "MaMpf-Version|1.2.3\n")
        File.write(File.join(dir, "extra.bin"), "x")

        expect(uploader.send(:valid_unpacked_structure?, dir)).to be(false)
      end
    end

    it "rejects oversized structure.mampf files" do
      uploader = described_class.new(:store)

      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "structure.mampf"),
                   "x" * (PdfUploader::MAX_STRUCTURE_BYTES + 1))

        expect(uploader.send(:valid_unpacked_structure?, dir)).to be(false)
      end
    end
  end
end
