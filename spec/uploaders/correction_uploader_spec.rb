require "rails_helper"

RSpec.describe(CorrectionUploader) do
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

  def text_fixture(extension, content)
    Tempfile.new(["upload", extension]).tap do |file|
      file.binmode
      file.write(content)
      file.rewind
    end
  end

  it "accepts pdf corrections" do
    submission = build(:valid_submission)
    file = fixture_file("manuscript.pdf")

    submission.correction = file

    expect(submission).to be_valid
    expect(submission.correction.metadata["mime_type"]).to eq("application/pdf")
  ensure
    file&.close
  end

  it "accepts text corrections" do
    submission = build(:valid_submission)
    file = text_fixture(".txt", "feedback")

    submission.correction = file

    expect(submission).to be_valid
    expect(submission.correction.metadata["mime_type"])
      .to eq("application/octet-stream").or(start_with("text/"))
  ensure
    file&.close!
  end

  it "rejects mismatched correction mime types even when the extension is allowed" do
    submission = build(:valid_submission)
    file = renamed_fixture("manuscript.pdf", ".zip")

    submission.correction = file

    expect(submission).not_to be_valid
    expect(submission.errors[:correction]).to include(
      I18n.t("submission.wrong_mime_type",
             mime_type: "application/pdf",
             accepted_mime_types: CorrectionUploader::ZIP_MIME_TYPES.join(", "))
    )
  ensure
    file&.close!
  end
end
