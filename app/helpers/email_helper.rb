module EmailHelper
  def email_image_tag(image, **)
    attachments.inline[image] = Rails.root.join("public/#{image}").read
    image_tag(attachments[image].url, **)
  end
end
