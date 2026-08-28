# ActiveStorage stores with the Disk service in every environment, so a direct
# upload arrives as a PUT whose body passes through Rails. That is where it is
# scanned -- before a byte reaches the store, the way MalwareScanGate does it for
# the Shrine endpoints.
#
# The verdict is kept on the blob. Unlike a Shrine cached file, a blob record
# never travels through the browser, so nothing has to be signed against
# tampering: what we wrote is what we read back.
class ActiveStorageScanGate
  # Beyond this, only the prefix is streamed to clamd -- a bounded check against
  # known malware near the start of a file, not a clean verdict for the whole of
  # it. Vignette slides carry video, which is why the bound exists at all.
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

    # Whether the file behind this key may be handed out: it carries a clean
    # verdict, or it is a variant our own processing derived from one.
    def cleared?(key)
      cleared_blob?(ActiveStorage::Blob.find_by(key: key))
    end

    # The same question where the blob has already been looked up.
    def cleared_blob?(blob)
      return false if blob.nil?
      return true if clean?(blob)

      blob.attachments.exists?(record_type: "ActiveStorage::VariantRecord")
    end

    def clean?(blob)
      blob.metadata.dig(MalwareScanGate::METADATA_KEY,
                        MalwareScanGate::STATUS_KEY) == MalwareScanGate::CLEAN_STATUS
    end
  end
end
