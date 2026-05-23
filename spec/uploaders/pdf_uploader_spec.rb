require "rails_helper"

RSpec.describe(PdfUploader) do
  describe "metadata extraction" do
    it "passes file paths to pdftk without invoking a shell" do
      uploader = described_class.new(:store)
      file = Tempfile.new(["manuscript; touch hacked", ".pdf"])
      file.binmode
      file.write(File.binread("#{SPEC_FILES}/manuscript.pdf"))
      file.rewind

      expect(uploader).to receive(:system) do |*args|
        expect(args[0...4]).to eq(["pdftk", file.path, "dump_data_utf8", "output"])
        File.write(args[4], "NumberOfPages: 7\n")
        true
      end.ordered

      expect(uploader).to receive(:system).with("pdftk", file.path,
                                                "unpack_files", "output",
                                                kind_of(String)).ordered
                                          .and_return(true)

      metadata = uploader.send(:extract_metadata, file, action: :upload)

      expect(metadata["pages"]).to eq(7)
    ensure
      file.close!
    end
  end
end
