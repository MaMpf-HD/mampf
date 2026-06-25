require "socket"
require "timeout"

class ClamavScanner
  CHUNK_SIZE = 1 * 1024 * 1024

  def initialize(host: ENV.fetch("CLAMAV_HOST", "clamav"),
                 port: ENV.fetch("CLAMAV_PORT", "3310").to_i,
                 timeout: ENV.fetch("CLAMAV_TIMEOUT", "15").to_i)
    @host = host
    @port = port
    @timeout = timeout
  end

  # Scans +io+ with clamd over INSTREAM.
  #
  # When +max_bytes+ is given, only that many leading bytes are streamed to
  # clamd; the app (not clamd) enforces the bound. This supports the bounded
  # video prefix scan, which is defense-in-depth and explicitly NOT a clean
  # verdict for the whole file.
  def scan(io, max_bytes: nil)
    return UploadScanResult.clean if Rails.env.test?

    scan_stream(io, max_bytes)
  rescue Timeout::Error
    UploadScanResult.timeout
  rescue SystemCallError, IOError, SocketError => e
    Rails.logger.warn("[clamav] scanner unavailable: #{e.class}: #{e.message}")
    UploadScanResult.unavailable(e.message)
  ensure
    io.rewind if io.respond_to?(:rewind)
  end

  private

    def scan_stream(io, max_bytes = nil)
      reply = Timeout.timeout(@timeout) do
        Socket.tcp(@host, @port, connect_timeout: @timeout) do |socket|
          socket.write("zINSTREAM\0")

          stream_chunks(io, socket, max_bytes)

          socket.write([0].pack("N"))
          socket.close_write
          socket.read
        end
      end

      parse_reply(reply.to_s)
    end

    # Streams +io+ to +socket+ in INSTREAM chunks, sending at most +max_bytes+
    # leading bytes when a bound is given (nil means the full stream).
    def stream_chunks(io, socket, max_bytes)
      io.rewind if io.respond_to?(:rewind)
      remaining = max_bytes

      until io.eof? || (remaining && remaining <= 0)
        read_size = remaining ? [CHUNK_SIZE, remaining].min : CHUNK_SIZE
        chunk = io.read(read_size)
        break if chunk.nil?

        socket.write([chunk.bytesize].pack("N"))
        socket.write(chunk)
        remaining -= chunk.bytesize if remaining
      end
    end

    def parse_reply(reply)
      response = reply.delete("\0").strip

      return UploadScanResult.clean if response.end_with?(": OK")

      if response.end_with?(" FOUND")
        signature = response.sub(/\A.*?:\s*/, "").delete_suffix(" FOUND")
        return UploadScanResult.infected(signature)
      end

      UploadScanResult.unavailable(response.empty? ? nil : response)
    end
end
