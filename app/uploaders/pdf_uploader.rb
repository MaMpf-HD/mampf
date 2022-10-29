require 'image_processing/mini_magick'

# PdfUploader Class
class PdfUploader < Shrine
  # shrine plugins
  plugin :upload_endpoint
  plugin :add_metadata
  plugin :determine_mime_type
  plugin :validation_helpers
  plugin :pretty_location
  plugin :derivatives, versions_compatibility: true

  # extract metadata from uploaded pdf:
  # - number of pages
  # - named destinations
  # - bookmarks with details (created by mampf.sty LATeX package)
  add_metadata do |io, context|
    if context[:action] == :upload
      Shrine.with_file(io) do |file|
        temp_file = Tempfile.new
        temp_folder = Dir.mktmpdir
        structure_path = "#{temp_folder}/structure.mampf"
        cmd = "pdftk #{file.path} dump_data_utf8 output #{temp_file.path} && "\
              "pdftk #{file.path} unpack_files output #{temp_folder}"
        exit_status = system(cmd)
        if exit_status
          meta = File.read(temp_file)
          # extract number of pages from pdftk output
          pages = /NumberOfPages: (\d*)/.match(meta)[1].to_i
          # extract lines that correspond to MaMpf-Label entries from LaTEX
          # package mampf.sty
          structure = if File.file?(structure_path)
                        open(structure_path, "r") do
                          |io| io.read.encode("UTF-8", invalid: :replace)
                        end
                      end
          structure ||= ''
          bookmarks = structure.scan(/MaMpf-Label\|(.*?)\n/).flatten
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
          linked_media = structure.scan(/MaMpf-Link\|(.*?)\n/)
                                  .flatten.map(&:to_i) - [0]
          mampf_sty_version = structure.scan(/MaMpf-Version\|(.*?)\n/).flatten
                                       .first
          { 'pages' => pages,
            'destinations' => result.map { |b| b['destination'] },
            'bookmarks' => result,
            'linked_media' => linked_media,
            'version' => mampf_sty_version }
        else
          { 'pages' => nil, 'destinations' => nil, 'bookmarks' => nil,
            'version' => nil }
        end
      end
    end
  end

  Attacher.validate do
    validate_mime_type_inclusion %w[application/pdf],
                                 message: 'falscher MIME-Typ'
  end

  # extract a screenshot from pdf and store it beside the pdf
  Attacher.derivatives_processor do |original|
    screenshot = ImageProcessing::MiniMagick.source(original).loader(page: 0)
                                            .convert('png')
                                            .resize_to_limit!(400, 565)
    { screenshot: screenshot }
  end
end
