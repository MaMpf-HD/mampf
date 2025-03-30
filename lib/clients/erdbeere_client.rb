module Clients
  class ErdbeereClient
    Response = Struct.new(:status, :body)

    def self.get(path, params: nil, headers: {}, &block)
      headers = headers.dup
      headers["Host"] = "localhost" if Rails.env.docker_development?
      ERDBEERE_CONNECTION.get(path, params, headers, &block)
    rescue Faraday::Error => e
      pp("---------------------------------")
      Rails.logger.error("ErdbeereClient.get error: #{e.message}")
      Response.new(500, { error: e.message }.to_json)
    end
  end
end
