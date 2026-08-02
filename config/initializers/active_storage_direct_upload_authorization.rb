# Defense-in-depth authorization for ActiveStorage direct uploads.
#
# ActiveStorage's stock direct-upload controller inherits from
# ActionController::Base (not ApplicationController), so the app's
# authenticate_user! filter never runs and POST /rails/active_storage/direct_uploads
# is otherwise open to anyone. The nginx edge already gates that exact path to
# content editors via the internal upload-authorization endpoint; this adds the
# matching in-app check so the protection does not depend on the edge config
# alone -- mirroring the defense-in-depth the Shrine uploaders get from
# MalwareScanGate.
#
# Wrapped in to_prepare because the engine controller is not loaded yet when
# initializers run. The before_action registration is guarded so dev reloads
# (which re-run to_prepare against the non-reloaded framework class) do not stack
# duplicate callbacks. UploadEndpointAuthorization is referenced by name, so it
# re-resolves to the current class on each request and stays reload-safe.
Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.class_eval do
    filter = :authorize_active_storage_direct_upload!
    unless _process_action_callbacks.any? { |callback| callback.filter == filter }
      before_action(filter)
    end

    private

      def authorize_active_storage_direct_upload!
        user = request.env["warden"]&.authenticate(scope: :user)
        return head(:unauthorized) if user.blank?
        return if UploadEndpointAuthorization.active_storage_authorized?(user: user)

        head(:forbidden)
      end
  end
end
