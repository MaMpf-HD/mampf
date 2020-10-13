require 'image_processing/mini_magick'

# UserPdfUploader Class
class SubmissionUploader < Shrine
  # shrine plugins
  plugin :determine_mime_type, analyzer: :marcel
  plugin :validation_helpers
  plugin :upload_endpoint, max_size: 10*1024*1024 # 10 MB
	plugin :default_storage, cache: :submission_cache, store: :submission_store

  Attacher.validate do
    validate_mime_type_inclusion %w[application/pdf],
    														 message:
    														 	 I18n.t('submission.manuscript_no_pdf')
		# maximum size of 10 MB
    validate_max_size 10*1024*1024,
    									message: I18n.t('submission.manuscript_size_too_big')
  end
end
