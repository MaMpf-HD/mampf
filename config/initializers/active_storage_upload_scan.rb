# Scans ActiveStorage uploads and holds back files that were never scanned.
#
# The controllers this hangs on belong to the ActiveStorage engine and are not
# loaded while initializers run, hence to_prepare -- which runs again on a code
# reload, hence the guard against registering the callbacks twice.
Rails.application.config.to_prepare do
  # Redirect, proxy and representation controllers all look their blob up
  # through this concern, so asking here covers every way to reach a file.
  ActiveStorage::SetBlob.prepend(Module.new do
    private

      def set_blob
        super
        return if @blob.nil? || performed?
        return if ActiveStorageScanGate.cleared_blob?(@blob)

        head :not_found
      end
  end)

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

        # A browser shows nothing of a failed direct upload but its status, so
        # these lines are for the log and for whoever asks with curl.
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

      # clamd reads the body to the end and the action then reads it again for
      # the store, so it is buffered into a file that Rack deletes when the
      # request is done.
      def buffered_request_body
        tempfile = Tempfile.new("active-storage-upload", binmode: true)
        IO.copy_stream(request.body, tempfile)
        tempfile.rewind
        (request.env["rack.tempfiles"] ||= []) << tempfile
        tempfile
      end
  end
end
