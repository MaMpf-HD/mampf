if Rails.env.development? || Rails.env.local?
  class UploadDebugLogging
    UPLOAD_PATHS = %w[
      /screenshots/upload
      /profile_image/upload
      /videos/upload
      /pdfs/upload
      /ggbs/upload
      /submissions/upload
      /corrections/upload
    ].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      return @app.call(env) unless upload_request?(request)

      Rails.logger.info(upload_request_log(request))

      status, headers, body = @app.call(env)

      Rails.logger.info(upload_response_log(request, status, headers))

      [status, headers, body]
    rescue StandardError => e
      Rails.logger.error(upload_exception_log(request, e))
      raise
    end

    private

      def upload_request?(request)
        request.post? && request.path.in?(UPLOAD_PATHS)
      end

      def upload_request_log(request)
        "[upload-debug] request path=#{request.path} content_type=#{request.content_type.inspect} " \
          "content_length=#{request.content_length.inspect} xhr=#{request.xhr?} " \
          "request_id=#{request.request_id} user_id=#{current_user_id(request).inspect}"
      end

      def upload_response_log(request, status, headers)
        "[upload-debug] response path=#{request.path} status=#{status} " \
          "location=#{headers['Location'].inspect} content_type=#{headers['Content-Type'].inspect} " \
          "request_id=#{request.request_id}"
      end

      def upload_exception_log(request, error)
        "[upload-debug] exception path=#{request.path} error_class=#{error.class} " \
          "message=#{error.message.inspect} request_id=#{request.request_id}"
      end

      def current_user_id(request)
        request.env["warden"]&.user&.id
      end
  end

  Rails.application.config.middleware.use UploadDebugLogging

  Shrine.subscribe(:metadata) do |event|
    Rails.logger.info(
      "[upload-debug] shrine event=metadata uploader=#{event[:uploader].name} " \
        "storage=#{event[:storage]} io_class=#{event[:io].class} duration=#{event.duration.round(1)}"
    )
  end

  Shrine.subscribe(:upload) do |event|
    metadata = event[:metadata] || {}

    Rails.logger.info(
      "[upload-debug] shrine event=upload uploader=#{event[:uploader].name} " \
        "storage=#{event[:storage]} location=#{event[:location].inspect} " \
        "filename=#{metadata['filename'].inspect} mime_type=#{metadata['mime_type'].inspect} " \
        "size=#{metadata['size'].inspect} duration=#{event.duration.round(1)}"
    )
  end
end