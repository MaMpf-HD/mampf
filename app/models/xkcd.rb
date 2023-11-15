# Xkcd model for getting Xkcd images
# Random change
class Xkcd
  def self.random
    max = JSON.parse(URI.open('https://xkcd.com/info.0.json').read)['num']
    comic_num = 1 + rand(max - 1)
    comic_num = 1 if comic_num == 404 # Avoid 404th comic ;)
    JSON.parse(URI.open("https://xkcd.com/#{comic_num}/info.0.json").read)
  rescue StandardError => e
    { error: e.message }
  end
end
