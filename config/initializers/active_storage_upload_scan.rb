# Virus-scans ActiveStorage direct uploads and refuses to hand out what was
# never scanned. See ActiveStorageScanGate for why the disk controller is the
# place for it.
#
# Wrapped in to_prepare and guarded against stacking, the way
# active_storage_direct_upload_authorization.rb is: the engine controller is not
# loaded when initializers run, and a dev reload would otherwise register the
# callbacks twice.
Rails.application.config.to_prepare do
  ActiveStorage::DiskController.class_eval do
    scan = :scan_direct_upload!
    gate = :require_scanned_file!

    unless _process_action_callbacks.any? { |callback| callback.filter == scan }
      before_action(scan, only: :update)
      before_action(gate, only: :show)
    end

    private

      def scan_direct_upload!
        token = decode_verified_token
        return if token.blank?

        request.env["rack.input"] = buffered_request_body
        result, scope = ActiveStorageScanGate.scan(request.body)

        # The browser only ever shows the status of a failed direct upload, so
        # the body is for the log and for whoever asks with curl.
        return render(plain: "infected", status: :unprocessable_content) if result.infected?
        return render(plain: "scanner unavailable", status: :service_unavailable) unless
          result.clean?

        ActiveStorageScanGate.record_verdict!(token[:key], scope: scope)
      end

      def require_scanned_file!
        key = decode_verified_key
        return if key.blank?
        return if ActiveStorageScanGate.cleared?(key[:key])

        head :not_found
      end

      # clamd has to read the whole body, and the action reads it again for the
      # store. Rack hands the tempfile back once the request is done.
      def buffered_request_body
        tempfile = Tempfile.new("active-storage-upload", binmode: true)
        IO.copy_stream(request.body, tempfile)
        tempfile.rewind
        (request.env["rack.tempfiles"] ||= []) << tempfile
        tempfile
      end
  end
end
