# Trix draws every attachment it is told is previewable into an <img>, and
# ActionText tells it so for anything ActiveStorage can represent -- which
# includes a PDF wherever a previewer is installed. A browser cannot render a
# PDF as an image, so what the editor showed was a broken frame. Only pictures
# are pictures.
Rails.application.config.to_prepare do
  ActiveStorage::Blob.class_eval do
    def previewable_attachable?
      image?
    end
  end
end
