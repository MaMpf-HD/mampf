require "rails_helper"

RSpec.describe(VttUploader) do
  def fixture_file(name)
    Rails.root.join(SPEC_FILES, name).open("rb")
  end

  def attacher_for(file)
    VttUploader::Attacher.new.tap do |attacher|
      attacher.assign(file)
    end
  end

  def renamed_fixture(source_name, extension)
    Tempfile.new(["upload", extension]).tap do |file|
      file.binmode
      file.write(Rails.root.join(SPEC_FILES, source_name).binread)
      file.rewind
    end
  end

  def oversized_vtt_fixture
    Tempfile.new(["upload", ".vtt"]).tap do |file|
      file.binmode
      file.write("WEBVTT\n\n")
      file.write("A" * (VttUploader::MAX_SIZE + 1))
      file.rewind
    end
  end

  it "accepts vtt files" do
    file = fixture_file("toc.vtt")
    attacher = attacher_for(file)

    expect(attacher.errors).to be_empty
    expect(attacher.file.metadata["mime_type"]).to eq("text/vtt")
  ensure
    file&.close
  end

  it "rejects non-vtt files even when renamed to .vtt" do
    file = renamed_fixture("manuscript.pdf", ".vtt")
    attacher = attacher_for(file)

    expect(attacher.errors).not_to be_empty
  ensure
    file&.close!
  end

  it "rejects oversized vtt files" do
    file = oversized_vtt_fixture
    attacher = attacher_for(file)

    expect(attacher.errors).to include(I18n.t("package.too_big"))
  ensure
    file&.close!
  end
end
