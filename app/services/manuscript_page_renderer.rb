require "timeout"

# Rasterizes the first page of a manuscript PDF so media can show a preview.
# MuPDF does the drawing instead of libvips, whose PDF loader is poppler-backed and
# blocked as untrusted since Rails 8.0.5.1 (CVE-2025-59933). Running it as a child
# process also keeps a hang or a crash away from the web worker.
class ManuscriptPageRenderer
  class RenderError < StandardError; end

  TIMEOUT = 20
  DPI = 150
  # A 458-byte PDF may declare a 14400pt page, which at DPI alone renders to
  # 30000x30000 and costs 5 GB. -w/-h cap that; twice the preview size leaves
  # libvips something to downsample from. The rlimits catch a future caller
  # that drops the caps.
  MAX_WIDTH = 800
  MAX_HEIGHT = 1130
  MEMORY_LIMIT = 512 * 1024 * 1024
  CPU_LIMIT = TIMEOUT
  OUTPUT_LIMIT = 32 * 1024 * 1024

  class << self
    # Returns an open Tempfile holding the PNG. The caller owns it.
    def render_first_page(pdf_path)
      png = Tempfile.new(["manuscript-page", ".png"])
      png.binmode
      draw(pdf_path, png.path)
      raise(RenderError, "mutool produced no output") unless File.size?(png.path)

      png
    rescue StandardError
      png&.close!
      raise
    end

    private

      def draw(pdf_path, out_path)
        pid = Process.spawn({}, "mutool", "draw", "-q", "-F", "png",
                            "-r", DPI.to_s, "-w", MAX_WIDTH.to_s, "-h", MAX_HEIGHT.to_s,
                            "-o", out_path, pdf_path, "1",
                            out: File::NULL, err: File::NULL, pgroup: true,
                            unsetenv_others: true, close_others: true,
                            rlimit_as: MEMORY_LIMIT, rlimit_cpu: CPU_LIMIT,
                            rlimit_fsize: OUTPUT_LIMIT)
        _pid, status = Timeout.timeout(TIMEOUT) { Process.wait2(pid) }
        return if status.success?

        raise(RenderError, "mutool exited with #{status.exitstatus}")
      rescue Errno::ENOENT
        raise(RenderError, "mutool is not installed")
      rescue Timeout::Error
        terminate_process_group(pid)
        raise(RenderError, "mutool timed out after #{TIMEOUT}s")
      end

      def terminate_process_group(pid)
        Process.kill("TERM", -pid)
        Timeout.timeout(1) { Process.wait(pid) }
      rescue Timeout::Error
        Process.kill("KILL", -pid)
        Process.wait(pid)
      rescue Errno::ECHILD, Errno::ESRCH
        nil
      end
  end
end
