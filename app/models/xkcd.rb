# Xkcd model for getting Xkcd images
class Xkcd
  IMAGE_HOST = "imgs.xkcd.com".freeze
  IMAGE_TYPES = ["image/png", "image/jpeg", "image/gif"].freeze

  def self.random
    max = JSON.parse(URI.open("https://xkcd.com/info.0.json").read)["num"]
    comic_num = 1 + rand(max - 1)
    comic_num = 1 if comic_num == 404 # Avoid 404th comic ;)
    comic = JSON.parse(URI.open("https://xkcd.com/#{comic_num}/info.0.json").read)
    comic.merge("img_data" => image_data(comic["img"]))
  rescue StandardError => e
    { error: e.message }
  end

  # The comic as a data URI. The server fetches it, so that the quiz taker's
  # browser does not contact xkcd just to finish a quiz.
  def self.image_data(url)
    uri = URI.parse(url)
    raise(ArgumentError, "unexpected image URL #{url}") unless
      uri.scheme == "https" && uri.host == IMAGE_HOST

    image = Net::HTTP.start(IMAGE_HOST, 443, use_ssl: true, open_timeout: 5,
                                             read_timeout: 5) do |http|
      http.get(uri.request_uri)
    end
    raise(ArgumentError, "unexpected image type #{image.content_type}") unless
      image.is_a?(Net::HTTPSuccess) && IMAGE_TYPES.include?(image.content_type)

    "data:#{image.content_type};base64,#{Base64.strict_encode64(image.body)}"
  end
end
