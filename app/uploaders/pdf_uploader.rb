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
  # - bookmarks with details (created by mampf.sty LATeX package)
  add_metadata do |io, context|
    # no metadata extraction for the screenshot which is generated during
    # storing
    unless context[:action] == :store && context[:version] == :screenshot
      Shrine.with_file(io) do |file|
        temp_file = Tempfile.new
        cmd = "pdftk #{file.path} dump_data_utf8 output #{temp_file.path}"
        exit_status = system(cmd)
        if exit_status
          meta = File.read(temp_file)
          # extract number of pages from pdftk output
          pages = /NumberOfPages: (\d*)/.match(meta)[1].to_i
          # extract lines that correspond to MaMpf-Label entries from LaTEX
          # package mampf.sty
          bookmarks = meta.scan(/BookmarkTitle: MaMpf-Label\|(.*?)\n/).flatten
          result = []
          bookmarks.each_with_index do |b,i|
            # extract bookmark data
            # line may look like this:
            # defn:erster-Tag|Definition|1.1|Erster Tag|1
            data = /(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*)\|(.*)\|(.*)\|(.*)/.match(b)
            details = { 'destination' => data[1], 'sort' => data[2],
                        'label' => data[3], 'description' => data[4],
                        'chapter' => data[5], 'section' => data[6],
                        'subsection' => data[7], 'page' => data[8],
                        'counter' => i }
            details['sort'] = 'Markierung' if details['sort'].blank?
            result.push(details)
          end
          linked_media = meta.scan(/BookmarkTitle: MaMpf-Link\|(.*?)\n/).flatten
                             .map(&:to_i) - [0]
          { 'pages' => pages,
            'destinations' => result.map { |b| b['destination'] },
            'bookmarks' => result,
            'linked_media' => linked_media }
        else
          { 'pages' => nil, 'destinations' => nil, 'bookmarks' => nil }
        end
      end
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
