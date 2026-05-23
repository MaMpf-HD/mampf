require "fileutils"
require "image_processing/mini_magick"
require "timeout"

# PdfUploader Class
class PdfUploader < Shrine
  MAX_FILE_SIZE = 50 * 1024 * 1024
  PDFTK_TIMEOUT = 10
  MAX_STRUCTURE_BYTES = 256 * 1024
  STRUCTURE_FILE_NAME = "structure.mampf".freeze
  UNPACK_ROOT = Rails.root.join("tmp/pdf_uploader")

  # shrine plugins
  plugin :upload_endpoint, max_size: MAX_FILE_SIZE
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
        Tempfile.create do |temp_file|
          with_unpack_folder do |temp_folder|
            structure_path = "#{temp_folder}/structure.mampf"
            exit_status = run_pdftk(file.path, "dump_data_utf8", "output",
                                    temp_file.path) &&
                          run_pdftk(file.path, "unpack_files", "output",
                                    temp_folder) &&
                          valid_unpacked_structure?(temp_folder)
            if exit_status
              meta = File.read(temp_file)
              # extract number of pages from pdftk output
              pages = /NumberOfPages: (\d*)/.match(meta)[1].to_i
              # extract lines that correspond to MaMpf-Label entries from LaTEX
              # package mampf.sty
              structure = if File.file?(structure_path)
                File.open(structure_path, "r") do |io_stream|
                  io_stream.read.encode("UTF-8", invalid: :replace)
                end
              end
              structure ||= ""
              bookmarks = structure.scan(/MaMpf-Label\|(.*?)\n/).flatten
              result = []
              bookmarks.each_with_index do |b, i|
                # extract bookmark data
                # line may look like this:
                # defn:erster-Tag|Definition|1.1|Erster Tag|1
                data = /(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*)\|(.*)\|(.*)\|(.*)/.match(b)
                details = { "destination" => data[1], "sort" => data[2],
                            "label" => data[3], "description" => data[4],
                            "chapter" => data[5], "section" => data[6],
                            "subsection" => data[7], "page" => data[8],
                            "counter" => i }
                details["sort"] = "Markierung" if details["sort"].blank?
                result.push(details)
              end
              linked_media = structure.scan(/MaMpf-Link\|(.*?)\n/)
                                      .flatten.map(&:to_i) - [0]
              mampf_sty_version = structure.scan(/MaMpf-Version\|(.*?)\n/).flatten
                                           .first
              { "pages" => pages,
                "destinations" => result.pluck("destination"),
                "bookmarks" => result,
                "linked_media" => linked_media,
                "version" => mampf_sty_version }
            else
              { "pages" => nil, "destinations" => nil, "bookmarks" => nil,
                "version" => nil }
            end
          end
        end
      end
    end
  end

  Attacher.validate do
    validate_mime_type_inclusion ["application/pdf"],
                                 message: "falscher MIME-Typ"
    validate_max_size MAX_FILE_SIZE,
                      message: I18n.t("submission.manuscript_size_too_big",
                                      max_size: "50 MB")
  end

  # extract a screenshot from pdf and store it beside the pdf
  Attacher.derivatives_processor do |original|
    screenshot = ImageProcessing::MiniMagick.source(original).loader(page: 0)
                                            .convert("png")
                                            .resize_to_limit!(400, 565)
    { screenshot: screenshot }
  end

  private

    def with_unpack_folder(&)
      FileUtils.mkdir_p(UNPACK_ROOT)

      Dir.mktmpdir("pdftk-", UNPACK_ROOT.to_s, &)
    end

    def run_pdftk(*)
      pid = Process.spawn("pdftk", *, out: File::NULL, err: File::NULL,
                                      pgroup: true)
      _pid, status = Timeout.timeout(PDFTK_TIMEOUT) { Process.wait2(pid) }
      status.success?
    rescue Timeout::Error
      terminate_process_group(pid)
      false
    end

    def terminate_process_group(pid)
      Process.kill("TERM", -pid)
      Timeout.timeout(1) { Process.wait(pid) }
    rescue Timeout::Error
      force_kill_process_group(pid)
    rescue Errno::ECHILD, Errno::ESRCH
      nil
    end

    def force_kill_process_group(pid)
      Process.kill("KILL", -pid)
      Process.wait(pid)
    rescue Errno::ECHILD, Errno::ESRCH
      nil
    end

    def valid_unpacked_structure?(temp_folder)
      unpacked_files = Dir.children(temp_folder)
      return true if unpacked_files.empty?
      return false unless unpacked_files == [STRUCTURE_FILE_NAME]

      File.size(File.join(temp_folder, STRUCTURE_FILE_NAME)) <=
        MAX_STRUCTURE_BYTES
    end
end
