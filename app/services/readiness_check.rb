require "securerandom"

class ReadinessCheck
  def call
    {
      database: dependency_status(:database) { database_ready? },
      redis: dependency_status(:redis) { redis_ready? },
      memcached: dependency_status(:memcached) { memcached_ready? }
    }
  end

  private

    def dependency_status(name)
      yield ? "ok" : "error"
    rescue StandardError => e
      Rails.logger.warn(
        "Readiness check failed for #{name}: #{e.class}: #{e.message}"
      )
      "error"
    end

    def database_ready?
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.select_value("SELECT 1").to_s == "1"
      end
    end

    def redis_ready?
      Sidekiq.redis do |connection|
        connection.ping == "PONG"
      end
    end

    def memcached_ready?
      cache_key = "readiness:#{SecureRandom.hex(8)}"

      Rails.cache.write(cache_key, "ok", expires_in: 1.minute)
      Rails.cache.read(cache_key) == "ok"
    ensure
      Rails.cache.delete(cache_key) if cache_key
    end
end
