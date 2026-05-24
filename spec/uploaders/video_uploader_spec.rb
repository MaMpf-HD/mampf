require "rails_helper"

RSpec.describe(VideoUploader) do
  def fixture_file(name)
    Rails.root.join(SPEC_FILES, name).open("rb")
  end

  def renamed_fixture(source_name, extension)
    Tempfile.new(["upload", extension]).tap do |file|
      file.binmode
      file.write(Rails.root.join(SPEC_FILES, source_name).binread)
      file.rewind
    end
  end

  it "accepts mp4 uploads" do
    medium = build(:valid_medium)
    file = fixture_file("talk.mp4")

    medium.video = file

    expect(medium).to be_valid
    expect(medium.video.metadata["mime_type"]).to eq("video/mp4")
  ensure
    file&.close
  end

  it "rejects non-mp4 uploads even when renamed to mp4" do
    medium = build(:valid_medium)
    file = renamed_fixture("manuscript.pdf", ".mp4")

    medium.video = file

    expect(medium).not_to be_valid
    expect(medium.errors[:video]).to include("wrong type")
  ensure
    file&.close!
  end
end
