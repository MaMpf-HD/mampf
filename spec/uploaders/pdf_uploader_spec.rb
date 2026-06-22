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

    it "returns nil pages when pdftk output omits NumberOfPages" do
      uploader = described_class.new(:store)
      file = Tempfile.new(["manuscript", ".pdf"])
      file.binmode
      file.write(File.binread("#{SPEC_FILES}/manuscript.pdf"))
      file.rewind

      allow(uploader).to receive(:run_pdftk) do |*args|
        File.write(args[3], "InfoKey: Title\n") if args[1] == "dump_data_utf8"
        true
      end

      metadata = uploader.send(:extract_metadata, file, action: :upload)

      expect(metadata["pages"]).to be_nil
    ensure
      file.close!
    end

    it "skips malformed MaMpf-Label rows" do
      uploader = described_class.new(:store)
      file = Tempfile.new(["manuscript", ".pdf"])
      file.binmode
      file.write(File.binread("#{SPEC_FILES}/manuscript.pdf"))
      file.rewind

      allow(uploader).to receive(:run_pdftk) do |*args|
        if args[1] == "dump_data_utf8"
          File.write(args[3], "NumberOfPages: 7\n")
        else
          File.write(File.join(args[3], "structure.mampf"),
                     "MaMpf-Label|broken\n" \
                     "MaMpf-Label|dest|Sort|1.1|Desc|1|1.1|1.1.0|7\n")
        end
        true
      end

      metadata = uploader.send(:extract_metadata, file, action: :upload)

      expect(metadata["bookmarks"].size).to eq(1)
      expect(metadata["bookmarks"].first["destination"]).to eq("dest")
      expect(metadata["bookmarks"].first["counter"]).to eq(0)
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

    it "returns false when pdftk cannot be spawned" do
      uploader = described_class.new(:store)

      allow(Process).to receive(:spawn).and_raise(Errno::ENOENT)

      expect(uploader.send(:run_pdftk, "input.pdf", "dump_data_utf8")).to be(false)
    end

    it "applies a child file-size limit when unpacking attachments" do
      uploader = described_class.new(:store)
      status = instance_double(Process::Status, success?: true)

      expect(Process).to receive(:spawn) do |*args|
        options = args.last
        expect(options[:rlimit_fsize])
          .to eq([PdfUploader::MAX_STRUCTURE_BYTES,
                  PdfUploader::MAX_STRUCTURE_BYTES])
        1234
      end
      allow(Timeout).to receive(:timeout).with(PdfUploader::PDFTK_TIMEOUT)
                                         .and_yield
      allow(Process).to receive(:wait2).with(1234).and_return([1234, status])

      result = uploader.send(:run_pdftk, "input.pdf", "unpack_files",
                             "output", "/tmp/pdf-dir",
                             file_size_limit: PdfUploader::MAX_STRUCTURE_BYTES)

      expect(result).to be(true)
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
