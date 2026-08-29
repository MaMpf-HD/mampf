require "rails_helper"

RSpec.describe("active_storage/blobs/_blob.html.erb", type: :view) do
  def blob_for(filename, content_type)
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(File.join(SPEC_FILES, filename)),
      filename: filename, content_type: content_type
    )
  end

  def render_blob(blob)
    render(partial: "active_storage/blobs/blob", locals: { blob: blob })
  end

  it "shows the preview of a file that has one" do
    render_blob(blob_for("image.png", "image/png"))

    assert_select("img")
  end

  it "offers a file without a preview for download" do
    blob = blob_for("manuscript.pdf", "application/pdf")
    allow(blob).to receive(:representable?).and_return(false)

    render_blob(blob)

    assert_select("a", text: "manuscript.pdf")
  end

  it "plays a video rather than previewing it" do
    render_blob(blob_for("talk.mp4", "video/mp4"))

    assert_select("video source")
    assert_select("img", false)
  end
end
