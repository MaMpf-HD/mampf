# Scans an ActiveStorage upload while its bytes are still in the request, and
# holds back a file that carries no clean verdict. Every environment stores with
# the Disk service, so the bytes do pass through Rails on their way in. The
# verdict is kept in the blob's metadata, which the browser never gets its hands
# on and which therefore needs no signature.
class ActiveStorageScanGate
  # Above this only the start of a file is streamed to clamd, which answers for
  # what it read and not for the rest. A bound is needed at all because a slide
  # can carry video.
  SCAN_MAX_BYTES = 32 * 1024 * 1024

  class << self
    def scan(io)
      scope = io.size.to_i > SCAN_MAX_BYTES ? "prefix" : "full"
      result = MalwareScanGate.scanner.scan(io, max_bytes: SCAN_MAX_BYTES)
      io.rewind

      [result, scope]
    end

    def record_verdict!(key, scope:)
      blob = ActiveStorage::Blob.find_by(key: key)
      return if blob.nil?

      blob.update!(metadata: blob.metadata.merge(
        MalwareScanGate::METADATA_KEY => {
          MalwareScanGate::STATUS_KEY => MalwareScanGate::CLEAN_STATUS,
          "scanner" => MalwareScanGate::SCANNER_NAME,
          "scanned_at" => Time.current.utc.iso8601,
          MalwareScanGate::SCOPE_KEY => scope
        }
      ))
    end

    def cleared?(key)
      cleared_blob?(ActiveStorage::Blob.find_by(key: key))
    end

    def cleared_blob?(blob)
      return false if blob.nil?

      clean?(blob) || clean?(origin_of(blob))
    end

    def clean?(blob)
      blob&.metadata&.dig(MalwareScanGate::METADATA_KEY,
                          MalwareScanGate::STATUS_KEY) == MalwareScanGate::CLEAN_STATUS
    end

    # A thumbnail and a PDF preview are made here, from a file that was scanned
    # on its way in, and carry no verdict of their own. ActiveStorage hangs a
    # thumbnail on a variant record and a preview on the blob it came from, so
    # the file it was made from is one attachment away either way.
    def origin_of(blob)
      attachment = blob.attachments.first
      return if attachment.nil?

      case attachment.record_type
      when "ActiveStorage::VariantRecord"
        ActiveStorage::VariantRecord.find_by(id: attachment.record_id)&.blob
      when "ActiveStorage::Blob"
        ActiveStorage::Blob.find_by(id: attachment.record_id) if attachment.name == "preview_image"
      end
    end
  end
end
