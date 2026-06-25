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

  def scan(io)
    return UploadScanResult.clean if Rails.env.test?

    scan_stream(io)
  rescue Timeout::Error
    UploadScanResult.timeout
  rescue SystemCallError, IOError, SocketError => e
    Rails.logger.warn("[clamav] scanner unavailable: #{e.class}: #{e.message}")
    UploadScanResult.unavailable(e.message)
  ensure
    io.rewind if io.respond_to?(:rewind)
  end

  private

    def scan_stream(io)
      reply = Timeout.timeout(@timeout) do
        Socket.tcp(@host, @port, connect_timeout: @timeout) do |socket|
          socket.write("zINSTREAM\0")

          io.rewind if io.respond_to?(:rewind)
          until io.eof?
            chunk = io.read(CHUNK_SIZE)
            socket.write([chunk.bytesize].pack("N"))
            socket.write(chunk)
          end

          socket.write([0].pack("N"))
          socket.close_write
          socket.read
        end
      end

      parse_reply(reply.to_s)
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
