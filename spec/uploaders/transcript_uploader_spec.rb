require "rails_helper"

RSpec.describe(TranscriptUploader, :mampfsearch) do
  def fixture_file(name)
    Rails.root.join(SPEC_FILES, name).open("rb")
  end

  def tempfile(content, extension: ".vtt")
    Tempfile.new(["upload", extension]).tap do |file|
      file.binmode
      file.write(content)
      file.rewind
    end
  end

  def attacher_for(file)
    TranscriptUploader::Attacher.new.tap do |attacher|
      attacher.assign(file)
    end
  end

  it "accepts a valid vtt file" do
    file = fixture_file("toc.vtt")
    attacher = attacher_for(file)

    expect(attacher.errors).to be_empty
    expect(attacher.file.metadata["mime_type"]).to eq("text/vtt")
  ensure
    file&.close
  end

  it "rejects oversized transcripts" do
    file = tempfile("WEBVTT\n\n00:00:00.000 --> 00:00:01.000\ntest\n")
    file.truncate(TranscriptUploader::MAX_SIZE + 1)
    file.rewind
    attacher = attacher_for(file)

    expect(attacher.errors).to include(I18n.t("package.too_big"))
  ensure
    file&.close!
  end

  it "rejects files with a non-vtt mime type" do
    file = tempfile("hello world", extension: ".txt")
    attacher = attacher_for(file)

    expect(attacher.errors).to include(
      I18n.t("submission.wrong_mime_type",
             mime_type: "application/octet-stream",
             accepted_mime_types: "text/vtt")
    )
  ensure
    file&.close!
  end

  it "rejects transcripts with too many cues" do
    cues = Array.new(TranscriptUploader::MAX_CUES + 1) do
      "00:00:00.000 --> 00:00:01.000\n"
    end
    file = tempfile("WEBVTT\n\n#{cues.join("\n")}")
    attacher = attacher_for(file)

    expect(attacher.errors).to include(
      I18n.t("submission.transcript_too_many_cues",
             max_cues: TranscriptUploader::MAX_CUES)
    )
  ensure
    file&.close!
  end

  describe ".structure_error" do
    it "returns nil for a valid vtt file" do
      file = fixture_file("toc.vtt")

      expect(described_class.structure_error(file)).to be_nil
    ensure
      file&.close
    end

    it "rejects content without a WEBVTT header" do
      file = tempfile("00:00:00.000 --> 00:00:01.000\ntest\n")

      expect(described_class.structure_error(file))
        .to eq(I18n.t("submission.invalid_transcript"))
    ensure
      file&.close!
    end

    it "rejects content that is not valid UTF-8" do
      file = tempfile("WEBVTT\n\n\xFF\xFE test\n".b)

      expect(described_class.structure_error(file))
        .to eq(I18n.t("submission.invalid_transcript"))
    ensure
      file&.close!
    end

    it "rejects malformed cue timings" do
      file = tempfile("WEBVTT\n\n00:00:11.12 --> 00:00:42.771\ntest\n")

      expect(described_class.structure_error(file))
        .to eq(I18n.t("submission.invalid_transcript"))
    ensure
      file&.close!
    end
  end
end
