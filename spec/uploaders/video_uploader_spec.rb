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

  def oversized_fixture(source_name, extension, max_size)
    Tempfile.new(["upload", extension]).tap do |file|
      file.binmode
      file.write(Rails.root.join(SPEC_FILES, source_name).binread)
      file.truncate(max_size + 1)
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
    expect(medium.errors[:video]).to include(
      I18n.t("submission.wrong_mime_type",
             mime_type: medium.video.metadata["mime_type"],
             accepted_mime_types: VideoUploader::ACCEPTED_MIME_TYPES.join(", "))
    )
  ensure
    file&.close!
  end

  it "rejects oversized mp4 uploads" do
    medium = build(:valid_medium)
    file = oversized_fixture("talk.mp4", ".mp4", VideoUploader::MAX_SIZE)

    medium.video = file

    expect(medium).not_to be_valid
    expect(medium.errors[:video]).to include(I18n.t("package.too_big"))
  ensure
    file&.close!
  end

  # Regression: a client must not be able to forge mime_type in the cached JSON
  # (the form's hidden field) to slip a non-mp4 past content-type validation.
  # restore_cached_data re-derives mime_type from the actual cached file.
  it "rejects a cached file whose mime_type was tampered to look like video" do
    medium = build(:valid_medium)
    file = fixture_file("manuscript.pdf")

    medium.video = file
    tampered = JSON.parse(medium.cached_video_data)
    tampered["metadata"]["mime_type"] = "video/mp4"
    medium.video = tampered.to_json

    expect(medium).not_to be_valid
    expect(medium.errors[:video]).to include(
      I18n.t("submission.wrong_mime_type",
             mime_type: medium.video.metadata["mime_type"],
             accepted_mime_types: VideoUploader::ACCEPTED_MIME_TYPES.join(", "))
    )
  ensure
    file&.close
  end
end
