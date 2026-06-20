require "rails_helper"

RSpec.describe(ScreenshotUploader) do
  def fixture_file(name)
    Rails.root.join(SPEC_FILES, name).open("rb")
  end

  def attacher_for(file)
    ScreenshotUploader::Attacher.new.tap do |attacher|
      attacher.assign(file)
    end
  end

  def oversized_image_fixture
    Tempfile.new(["upload", ".png"]).tap do |file|
      file.binmode
      file.write(Rails.root.join(SPEC_FILES, "image.png").binread)
      file.write("a" * (ScreenshotUploader::MAX_SIZE + 1))
      file.rewind
    end
  end

  def oversized_dimensions_image_fixture
    Tempfile.new(["upload", ".png"]).tap do |file|
      file.binmode
      MiniMagick::Tool::Convert.new do |convert|
        convert.size("5000x5000")
        convert.xc("white")
        convert << file.path
      end
      file.rewind
    end
  end

  it "accepts valid screenshots" do
    file = fixture_file("image.png")
    attacher = attacher_for(file)

    expect(attacher.errors).to be_empty
    expect(attacher.file.metadata["mime_type"]).to eq("image/png")
  ensure
    file&.close
  end

  it "rejects oversized screenshots" do
    file = oversized_image_fixture
    attacher = attacher_for(file)

    expect(attacher.errors).to include(I18n.t("package.too_big"))
  ensure
    file&.close!
  end

  it "rejects screenshots with excessive dimensions" do
    file = oversized_dimensions_image_fixture
    attacher = attacher_for(file)

    expect(attacher.errors).to include(
      I18n.t("image.too_large_dimensions", max_width: 4096, max_height: 4096)
    )
  ensure
    file&.close!
  end
end
