module UploadsHelper
  # Signs what this upload area is for, so the endpoint can ask the same
  # question again when the file arrives. See UploadIntent.
  def upload_intent_token(uploader_class, target: nil, action: nil)
    UploadIntent.mint(user: current_user, uploader_class: uploader_class,
                      target: target, action: action)
  end
end
