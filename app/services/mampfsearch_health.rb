# Polls the MampfSearch `/ready` endpoint in the background and caches the
# result globally (once per app, not per user), so that search/transcribe UI
# can be disabled up front without ever blocking a page load on a connection
# attempt to MampfSearch.
class MampfsearchHealth
  CACHE_KEY = "mampfsearch/health".freeze
  CACHE_TTL = 5.minutes

  UNAVAILABLE = { "search" => false, "ingest" => false }.freeze

  def call
    result = SearchClient.instance.configured? ? probe : UNAVAILABLE
    Rails.cache.write(CACHE_KEY, result, expires_in: CACHE_TTL)
    result
  end

  def self.search_available?
    read_capability("search")
  end

  def self.ingest_available?
    read_capability("ingest")
  end

  # Unknown health: unavailable in production, so no jobs are sent before the first probe.
  # Available in development: the cache is per process, so only Sidekiq sees the probe result.
  def self.read_capability(capability)
    cached = Rails.cache.read(CACHE_KEY)
    return Rails.env.development? if cached.nil?

    cached[capability] == true
  end

  private

    def probe
      health = SearchClient.instance.health
      capabilities = health.is_a?(Hash) ? health.fetch("capabilities", {}) : {}
      {
        "search" => capabilities["search"] == true,
        "ingest" => capabilities["ingest"] == true
      }
    rescue StandardError => e
      Rails.logger.warn("MampfSearch health probe failed (#{e.class}): #{e.message}")
      UNAVAILABLE
    end
end
