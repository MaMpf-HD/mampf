require "image_processing/vips"
require "pdf-reader"
require "timeout"

# PdfUploader Class
class PdfUploader < Shrine
  MAX_FILE_SIZE = 50 * 1024 * 1024
  TOOL_TIMEOUT = 10
  MAX_STRUCTURE_BYTES = 256 * 1024
  STRUCTURE_FILE_NAME = "structure.mampf".freeze

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
        structure = read_mampf_structure(file.path) || ""

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

    # Extract page count using the pdf-reader gem (pure Ruby, no CLI needed).
    def pdf_page_count(path)
      PDF::Reader.new(path).page_count
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError,
           PDF::Reader::EncryptedPDFError, Errno::ENOENT, ArgumentError
      nil
    end

    # Extract the structure.mampf embedded attachment using qpdf.
    # Returns the file content as a UTF-8 string, or nil if unavailable.
    def read_mampf_structure(file_path)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + TOOL_TIMEOUT
      reader, writer = IO.pipe
      pid = Process.spawn("qpdf", "--show-attachment=#{STRUCTURE_FILE_NAME}",
                          file_path,
                          out: writer, err: File::NULL, pgroup: true)
      writer.close

      output = +""
      loop do
        remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        raise(Timeout::Error) if remaining <= 0

        ready = reader.wait_readable(remaining)
        raise(Timeout::Error) unless ready

        chunk = reader.read_nonblock(16 * 1024, exception: false)
        case chunk
        when :wait_readable
          next
        when nil
          break
        else
          output << chunk
          if output.bytesize > MAX_STRUCTURE_BYTES
            terminate_process_group(pid)
            return nil
          end
        end
      end

      remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
      raise(Timeout::Error) if remaining <= 0

      _pid, status = Timeout.timeout(remaining) { Process.wait2(pid) }
      return nil unless status.success?

      output.force_encoding("UTF-8").encode("UTF-8", invalid: :replace,
                                                     undef: :replace)
    rescue SystemCallError
      nil
    rescue Timeout::Error
      terminate_process_group(pid) if pid
      nil
    ensure
      writer&.close unless writer.nil? || writer.closed?
      reader&.close unless reader.nil? || reader.closed?
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
