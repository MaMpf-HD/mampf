ERDBEERE_API_URL = ENV.fetch("ERDBEERE_API")

ERDBEERE_CONNECTION = Faraday.new(url: ERDBEERE_API_URL) do |conn|
  conn.adapter(Faraday.default_adapter)
end
