require "fileutils"
require "image_processing/vips"
require "pdf-reader"
require "timeout"

# PdfUploader Class
class PdfUploader < Shrine
  MAX_FILE_SIZE = 50 * 1024 * 1024
  TOOL_TIMEOUT = 10
  MAX_STRUCTURE_BYTES = 256 * 1024
  STRUCTURE_FILE_NAME = "structure.mampf".freeze
  UNPACK_ROOT = Rails.root.join("tmp/pdf_uploader")

  # shrine plugins
  plugin :upload_endpoint, max_size: MAX_FILE_SIZE
  plugin :add_metadata
  plugin :determine_mime_type, analyzer: :marcel
  plugin :validation_helpers
  plugin :pretty_location
  plugin :derivatives, versions_compatibility: true

  # extract metadata from uploaded pdf:
  # - number of pages
  # - named destinations
  # - bookmarks with details (created by mampf.sty LaTeX package)
  add_metadata do |io, context|
    if context[:action] == :upload
      Shrine.with_file(io) do |file|
        # Extract page count using pdf-reader (pure Ruby, no external tool)
        pages = pdf_page_count(file.path)

        # Extract structure.mampf (embedded by mampf.sty LaTeX package) using qpdf
        structure = with_unpack_folder do |temp_folder|
          read_mampf_structure(file.path, temp_folder)
        end
        structure ||= ""

        # extract lines that correspond to MaMpf-Label entries from LaTeX
        # package mampf.sty
        bookmarks = structure.scan(/MaMpf-Label\|(.*?)\n/).flatten
        result = []
        bookmarks.each do |b|
          # extract bookmark data
          # line may look like this:
          # defn:erster-Tag|Definition|1.1|Erster Tag|1
          data = /(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*)\|(.*)\|(.*)\|(.*)/.match(b)
          next unless data

          details = { "destination" => data[1], "sort" => data[2],
                      "label" => data[3], "description" => data[4],
                      "chapter" => data[5], "section" => data[6],
                      "subsection" => data[7], "page" => data[8],
                      "counter" => result.length }
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
    screenshot = ImageProcessing::Vips.source(original).loader(page: 0, dpi: 150)
                                      .convert("png")
                                      .resize_to_limit!(400, 565)
    { screenshot: screenshot }
  end

  private

    def with_unpack_folder(&)
      FileUtils.mkdir_p(UNPACK_ROOT)
      Dir.mktmpdir("pdf-", UNPACK_ROOT.to_s, &)
    end

    # Extract page count using the pdf-reader gem (pure Ruby, no CLI needed).
    def pdf_page_count(path)
      PDF::Reader.new(path).page_count
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError,
           PDF::Reader::EncryptedPDFError, Errno::ENOENT, ArgumentError
      nil
    end

    # Extract the structure.mampf embedded attachment using qpdf.
    # Returns the file content as a UTF-8 string, or nil if unavailable.
    def read_mampf_structure(file_path, temp_folder)
      structure_path = File.join(temp_folder, STRUCTURE_FILE_NAME)
      out_file = File.open(structure_path, "w")
      pid = Process.spawn("qpdf", "--show-attachment=#{STRUCTURE_FILE_NAME}",
                          file_path,
                          out: out_file, err: File::NULL, pgroup: true)
      _pid, status = Timeout.timeout(TOOL_TIMEOUT) { Process.wait2(pid) }
      out_file.close
      return nil unless status.success? && File.exist?(structure_path)
      return nil if File.size(structure_path) > MAX_STRUCTURE_BYTES

      File.open(structure_path, "r") do |io|
        io.read.encode("UTF-8", invalid: :replace)
      end
    rescue SystemCallError
      nil
    rescue Timeout::Error
      terminate_process_group(pid)
      nil
    ensure
      out_file&.close unless out_file&.closed?
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
end
