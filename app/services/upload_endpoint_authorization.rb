class UploadEndpointAuthorization
  UPLOADERS = {
    "correction" => CorrectionUploader,
    "geogebra" => GeogebraUploader,
    "pdf" => PdfUploader,
    "screenshot" => ScreenshotUploader,
    "video" => VideoUploader
  }.freeze

  class << self
    def authorized?(uploader_class:, user:)
      case uploader_class.name
      when "VideoUploader"
        content_editor?(user) || user&.speaker?
      when "PdfUploader", "GeogebraUploader", "ScreenshotUploader"
        content_editor?(user)
      when "CorrectionUploader"
        content_editor?(user) || user&.tutor?
      else
        true
      end
    end

    def uploader_class_for(key)
      UPLOADERS[key.to_s]
    end

    private

      def content_editor?(user)
        user.present? && (user.admin? || user.teacher? || user.editor?)
      end
  end
end
