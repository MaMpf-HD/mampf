require "rails_helper"

RSpec.describe(Seeds::PackageSupport) do
  # The task runs against the development store; the spec writes into a corner
  # of it that it cleans up again.
  let(:prefix) { "uploads/store/seed-package-spec" }
  let(:directory) { Rails.public_path.join(prefix) }
  let(:archive) { Rails.root.join("tmp/seed-package-spec.zip") }

  before do
    allow(described_class).to receive(:ensure_development!)
    allow(Shrine).to receive(:storages).and_return(
      store: Shrine::Storage::FileSystem.new("public", prefix: prefix)
    )
    FileUtils.mkdir_p(directory)
  end

  after do
    FileUtils.rm_rf(directory)
    FileUtils.rm_f(archive)
  end

  def attach!(record, column, id, derivative: nil)
    data = { "id" => id, "storage" => "store" }
    data["derivatives"] = { "thumb" => { "id" => derivative, "storage" => "store" } } if derivative
    # rubocop:disable Rails/SkipsModelValidations
    record.update_columns(column => data.to_json)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def write!(name)
    File.write(directory.join(name), "seed")
  end

  describe ".paths_in" do
    it "reads the file an attachment points at" do
      data = { "id" => "medium/1/video/clip.mp4", "storage" => "store" }

      expect(described_class.paths_in(data))
        .to eq([Rails.public_path.join(prefix, "medium/1/video/clip.mp4").to_s])
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

  describe ".referenced_files" do
    it "finds what a record points at, derivative and rich-text blob included" do
      write!("sheet.pdf")
      write!("thumbnail.png")
      attach!(create(:valid_medium), :manuscript_data, "sheet.pdf",
              derivative: "thumbnail.png")
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("blob"),
                                                    filename: "vignette.png")

      files = described_class.referenced_files

      expect(files).to include(directory.join("sheet.pdf").to_s,
                               directory.join("thumbnail.png").to_s,
                               blob.service.path_for(blob.key))
    end
  end

  describe ".package!" do
    it "packs what is there, under the path the archive is unpacked to" do
      write!("sheet.pdf")
      attach!(create(:valid_medium), :manuscript_data, "sheet.pdf")

      described_class.package!(path: archive.to_s)

      expect(entries(archive)).to include("#{prefix}/sheet.pdf")
    end

    it "reports what a record points at but nobody stored, and leaves it out" do
      attach!(create(:valid_medium), :manuscript_data, "gone.pdf")

      missing = described_class.package!(path: archive.to_s)

      expect(missing).to eq([directory.join("gone.pdf").to_s])
      expect(entries(archive)).not_to include("#{prefix}/gone.pdf")
    end
  end

  def entries(path)
    Zip::File.open(path) { |zip| zip.map(&:name) }
  end
end
