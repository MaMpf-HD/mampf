# Mints the intent a form would put on the page, for request specs that post
# to an upload endpoint.
module UploadIntentHelper
  def upload_intent_headers(uploader_class, user:, target: nil, action: nil)
    {
      "X-Upload-Intent" => UploadIntent.mint(user: user, uploader_class: uploader_class,
                                             target: target, action: action)
    }
  end
end

RSpec.configure do |config|
  config.include UploadIntentHelper, type: :request
end
