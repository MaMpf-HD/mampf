require "rails_helper"

RSpec.describe("Attachments offered to the Trix editor") do
  def trix_html_for(filename, content_type)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(File.join(SPEC_FILES, filename)),
      filename: filename, content_type: content_type
    )
    ActionText::Content.new(ActionText::Attachment.from_attachable(blob).to_html)
                       .to_trix_html
  end

  it "keeps a picture previewable, which the editor can draw" do
    expect(trix_html_for("image.png", "image/png")).to include("previewable")
  end

  it "does not offer a PDF as a preview, which the editor cannot draw" do
    expect(trix_html_for("manuscript.pdf", "application/pdf")).not_to include("previewable")
  end
end
