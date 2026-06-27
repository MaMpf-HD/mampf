class UploadEndpointAuthorization
  UPLOADERS = {
    "correction" => CorrectionUploader,
    "geogebra" => GeogebraUploader,
    "pdf" => PdfUploader,
    "profile_image" => ProfileimageUploader,
    "screenshot" => ScreenshotUploader,
    "video" => VideoUploader
  }.freeze

  # ActiveStorage's stock direct-upload controller ships without any
  # authentication of its own. The only app surface that uses it is editor-
  # authored vignette rich-text (Trix), so the edge gate restricts it to
  # content editors. This key is not a Shrine uploader; it maps directly to a
  # role rule (see .active_storage_authorized?).
  ACTIVE_STORAGE_KEY = "active_storage".freeze

  class << self
    def authorized?(uploader_class:, user:)
      case uploader_class.name
      when "VideoUploader"
        # Keep video intentionally broad until we have target-bound signed
        # upload intent: a historic editor of an existing non-talk medium
        # must still be able to replace the video on that medium.
        content_editor?(user) || user&.speaker?
      when "PdfUploader", "GeogebraUploader", "ScreenshotUploader",
           "ProfileimageUploader"
        content_editor?(user)
      when "CorrectionUploader"
        content_editor?(user) || user&.tutor?
      when "SubmissionUploader"
        # Manuscript submissions are open to any authenticated user (and sit
        # behind `authenticate :user`); require a present user so nil callers
        # fail closed. Other uploaders fall through to a raise.
        user.present?
      else
        raise(ArgumentError, "Unhandled uploader: #{uploader_class.name}")
      end
    end

    # Coarse authorization for the stock ActiveStorage direct-upload endpoint.
    # See ACTIVE_STORAGE_KEY for why this is gated to content editors.
    def active_storage_authorized?(user:)
      content_editor?(user)
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
