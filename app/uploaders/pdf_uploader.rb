require "image_processing/mini_magick"

class PdfUploader < Shrine
  plugin :add_metadata
  plugin :determine_mime_type
  plugin :validation_helpers
  plugin :processing
  plugin :versions
  plugin :delete_raw
  plugin :pretty_location

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
        destinations.push d.to_s.force_encoding('UTF-8')
                           .string_between_markers('(',')')
       end
      { "pages" => pdf.pages.size, "destinations" => destinations }
    else
      { "pages" => nil, "destinations" => nil }
    end
  end

  Attacher.validate do
    validate_mime_type_inclusion %w[application/pdf], message: 'falscher MIME-Typ'
  end

  process(:store) do |io, context|
    original = io.download
    screenshot   = ImageProcessing::MiniMagick.source(original).loader(page: 0)
                                              .convert("png")
                                              .resize_to_limit!(400, 565)
    original.close!
    { original: io, screenshot: screenshot }
  end
end
