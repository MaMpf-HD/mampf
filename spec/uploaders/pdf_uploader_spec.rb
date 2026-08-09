require "rails_helper"
require "rbconfig"

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
      reader, writer = IO.pipe

      allow(Process).to receive(:spawn).and_return(1234)
      allow(IO).to receive(:pipe).and_return([reader, writer])
      allow(reader).to receive(:wait_readable).and_return(nil)
      expect(uploader).to receive(:terminate_process_group).with(1234)

      result = uploader.send(:read_mampf_structure, "input.pdf")
      expect(result).to be_nil
    ensure
      reader.close unless reader.closed?
      writer.close unless writer.closed?
    end

    it "returns nil when qpdf cannot be spawned" do
      uploader = described_class.new(:store)

      allow(Process).to receive(:spawn).and_raise(Errno::ENOENT)

      result = uploader.send(:read_mampf_structure, "input.pdf")
      expect(result).to be_nil
    end

    it "returns nil when the extracted attachment exceeds the byte limit" do
      uploader = described_class.new(:store)
      original_spawn = Process.method(:spawn)

      allow(Process).to receive(:spawn) do |_command, *_args, out:, err:, pgroup:|
        original_spawn.call(RbConfig.ruby, "-e",
                            "STDOUT.write('A' * #{PdfUploader::MAX_STRUCTURE_BYTES + 1})",
                            out: out, err: err, pgroup: pgroup)
      end

      result = uploader.send(:read_mampf_structure, "input.pdf")
      expect(result).to be_nil
    end
  end

  describe "screenshot derivative" do
    it "renders the first page of the PDF" do
      original = File.open("#{SPEC_FILES}/manuscript.pdf", "rb")

      derivatives = described_class::Attacher.derivatives_processor(:default)
                                             .call(original)

      expect(derivatives[:screenshot]).to be_present
      expect(Vips::Image.new_from_file(derivatives[:screenshot].path).width)
        .to be_positive
    ensure
      original.close
    end
  end

  # Active Storage blocks libvips' unfuzzed loaders since Rails 8.0.5.1, which took
  # the PDF loader with it and broke every manuscript upload.
  describe "the libvips PDF loader" do
    it "is available" do
      expect { Vips::Image.pdfload("#{SPEC_FILES}/manuscript.pdf") }
        .not_to raise_error
    end

    it "is the only unfuzzed loader we unblock" do
      ["svgload", "magickload", "fitsload", "jxlload"].each do |loader|
        expect { Vips::Image.public_send(loader, "#{SPEC_FILES}/manuscript.pdf") }
          .to raise_error(Vips::Error, /blocked/), "#{loader} is no longer blocked"
      end
    end
  end
end
