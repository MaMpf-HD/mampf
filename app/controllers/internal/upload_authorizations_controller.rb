module Internal
  class UploadAuthorizationsController < ApplicationController
    skip_before_action :store_user_location!
    skip_before_action :authenticate_user!
    skip_before_action :set_current_user

    def show
      authorize = authorization_for(params[:uploader])
      return head(:not_found) unless authorize

      I18n.with_locale(upload_locale) do
        return denied!(:unauthorized, I18n.t("devise.failure.unauthenticated")) unless upload_user

        return denied!(:forbidden, I18n.t("submission.upload_failure_unauthorized")) unless
          authorize.call(upload_user)

        head :no_content
      end
    end

    private

      # Resolves the requested key to an authorization predicate, or nil if the
      # key is unknown (so the caller can answer 404). ActiveStorage's stock
      # direct-upload endpoint is not a Shrine uploader, so it is dispatched
      # separately from the Shrine uploader classes.
      def authorization_for(key)
        if key == UploadEndpointAuthorization::ACTIVE_STORAGE_KEY
          lambda do |user|
            UploadEndpointAuthorization.active_storage_authorized?(user: user)
          end
        elsif (uploader_class = UploadEndpointAuthorization.uploader_class_for(key))
          lambda do |user|
            UploadEndpointAuthorization.authorized?(uploader_class: uploader_class, user: user)
          end
        end
      end

      def denied!(status, message)
        response.set_header("X-Upload-Authorization-Message", message)
        head status
      end

      def upload_locale
        locale = params[:locale].presence ||
                 upload_user&.locale.presence ||
                 cookies["locale"].presence ||
                 I18n.default_locale.to_s

        locale = I18n.default_locale.to_s unless locale.in?(I18n.available_locales.map(&:to_s))
        locale
      end

      def upload_user
        @upload_user ||= request.env["warden"]&.authenticate(scope: :user)
      end
  end
end
