require "cgi"
require "uri"

module DeviseMailTokenHelper
  def devise_mail_token(mail, param_name)
    body = if mail.html_part.present?
      mail.html_part.body.to_s
    else
      mail.body.to_s
    end

    decoded_body = CGI.unescapeHTML(body)
    match = decoded_body.match(/#{Regexp.escape(param_name.to_s)}=([^&"\s]+)/)
    raise("Could not find #{param_name} in mail body") unless match

    CGI.unescape(match[1])
  end
end

RSpec.configure do |config|
  config.include DeviseMailTokenHelper, type: :request
end
