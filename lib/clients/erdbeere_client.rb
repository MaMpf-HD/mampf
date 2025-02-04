module Clients
  class Clients::ErdbeereClient
    def self.get(path, params: nil, headers: {}, &block)
      headers = headers.dup
      headers["Host"] = "localhost" if Rails.env.docker_development?
      ERDBEERE_CONNECTION.get(path, params, headers, &block)
    end
  end
end
