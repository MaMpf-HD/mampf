module EmailHelper
  def email_image_tag(image, **options)
    attachments.inline[image] = Rails.root.join("public/#{image}").read
    image_tag attachments[image].url, **options
  end
end
