require "rails_helper"

RSpec.describe(Seeds::PackageSupport) do
  describe ".paths_in" do
    before do
      allow(Shrine).to receive(:storages).and_return(
        store: Shrine::Storage::FileSystem.new("public", prefix: "uploads/store")
      )
    end

    it "reads the file an attachment points at" do
      data = { "id" => "medium/1/video/clip.mp4", "storage" => "store" }

      expect(described_class.paths_in(data))
        .to eq([Rails.public_path.join("uploads/store/medium/1/video/clip.mp4").to_s])
    end

    it "takes the derivatives along, which are files of their own" do
      data = {
        "id" => "sheet.pdf", "storage" => "store",
        "derivatives" => { "thumb" => { "id" => "thumbnail.png", "storage" => "store" } }
      }

      expect(described_class.paths_in(data).map { |path| File.basename(path) })
        .to eq(["sheet.pdf", "thumbnail.png"])
    end

    it "passes over an attachment in a storage that keeps no files" do
      data = { "id" => "clip.mp4", "storage" => "cache" }

      expect(described_class.paths_in(data)).to be_empty
    end
  end
end
