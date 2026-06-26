module Internal
  class UploadAuthorizationsController < ApplicationController
    skip_before_action :store_user_location!
    skip_before_action :authenticate_user!
    skip_before_action :set_current_user

    def show
      uploader_class = UploadEndpointAuthorization.uploader_class_for(params[:uploader])
      return head(:not_found) unless uploader_class

      I18n.with_locale(upload_locale) do
        return denied!(:unauthorized, I18n.t("devise.failure.unauthenticated")) unless upload_user

        return denied!(:forbidden, I18n.t("submission.upload_failure_unauthorized")) unless
          UploadEndpointAuthorization.authorized?(
            uploader_class: uploader_class,
            user: upload_user
          )

        head :no_content
      end
    end

    private

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
