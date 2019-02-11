require 'image_processing/mini_magick'

# PdfUploader Class
class PdfUploader < Shrine
  # shrine plugins
  plugin :add_metadata
  plugin :determine_mime_type
  plugin :validation_helpers
  plugin :processing
  plugin :versions
  plugin :delete_raw
  plugin :pretty_location

  # extract metadata from uploaded pdf:
  # - number of pages
  # - named destinations
  add_metadata do |io, context|
    pdf = Shrine.with_file(io) do |file|
      begin
        Origami::PDF.read(file.path)
      rescue StandardError => e
        puts "Pdf Error, will ignore: #{e}"
      end
    end
    if pdf.present?
      destinations = []
      pdf.each_named_dest do |d|
        # enforce UTF-8, otherwise ther are problems
        destinations.push(d.value.force_encoding('UTF-8'))
      end
      # reject named destinations including spaces or "."
      # or the generic "Doc-Start" destination
      destinations.reject! do |d|
        d.include?(' ') || d.include?('.') || d == 'Doc-Start'
      end
      { 'pages' => pdf.pages.size, 'destinations' => destinations }
    else
      { 'pages' => nil, 'destinations' => nil }
    end
  end

  Attacher.validate do
    validate_mime_type_inclusion %w[application/pdf],
                                 message: 'falscher MIME-Typ'
  end

  # extract a screenshot from pdf and store it beside the pdf
  process(:store) do |io, context|
    original = io.download
    screenshot = ImageProcessing::MiniMagick.source(original).loader(page: 0)
                                            .convert('png')
                                            .resize_to_limit!(400, 565)
    original.close!
    { original: io, screenshot: screenshot }
  end
end
