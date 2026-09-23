# Puts a PDF on a lecture's home page the way server-side code does: an
# opened file through the scan. A form's file is refused by the attacher.
module HomeAttachmentHelper
  def attach_home_pdf(lecture, content = "%PDF-1.4 demo", name = "program.pdf")
    Tempfile.create(["home_attachment", ".pdf"]) do |file|
      file.binmode
      file.write(content)
      file.rewind
      lecture.home_attachment_attacher.attach_cached(file, metadata: { "filename" => name })
    end
    lecture
  end
end

RSpec.configure do |config|
  config.include HomeAttachmentHelper, type: :model
  config.include HomeAttachmentHelper, type: :request
end
