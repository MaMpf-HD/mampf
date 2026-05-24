require "rails_helper"
require "zlib"

RSpec.describe(SubmissionUploader) do
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

  def gzip_fixture
    Tempfile.new(["upload", ".tar.gz"]).tap do |file|
      Zlib::GzipWriter.open(file.path) do |gz|
        gz.write("archive")
      end
      file.open
      file.binmode
      file.rewind
    end
  end

  it "accepts pdf submissions" do
    submission = build(:valid_submission)
    file = fixture_file("manuscript.pdf")

    submission.manuscript = file

    expect(submission).to be_valid
    expect(submission.manuscript.metadata["mime_type"]).to eq("application/pdf")
  ensure
    file&.close
  end

  it "accepts tar gz submissions" do
    lecture = build(:lecture)
    submission = build(:valid_submission,
                       assignment: build(:assignment,
                                         lecture: lecture,
                                         accepted_file_type: ".tar.gz"),
                       tutorial: build(:tutorial, lecture: lecture))
    file = gzip_fixture

    submission.manuscript = file

    expect(submission).to be_valid
    expect(submission.manuscript.metadata["mime_type"]).to be_in(
      Assignment.accepted_mime_types[".tar.gz"]
    )
  ensure
    file&.close!
  end

  it "rejects mismatched manuscript mime types even when the extension is allowed" do
    submission = build(:valid_submission)
    file = renamed_fixture("talk.mp4", ".pdf")

    submission.manuscript = file

    expect(submission).not_to be_valid
    expect(submission.errors[:manuscript]).to include(
      I18n.t("submission.wrong_mime_type",
             mime_type: "video/mp4",
             accepted_mime_types: "application/pdf")
    )
  ensure
    file&.close!
  end
end
