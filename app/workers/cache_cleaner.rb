class CacheCleaner
  include Sidekiq::Worker

  # How long an un-promoted upload may linger in cache before it is swept.
  # Cache entries only exist between upload and form-save (promotion is
  # synchronous, single editing session), so this only needs to outlast a long
  # edit, not days. Kept short to limit orphan/disk footprint. Override with
  # CACHE_MAX_AGE_HOURS; a non-positive value falls back to the default so a
  # misconfiguration cannot wipe in-progress uploads.
  DEFAULT_MAX_AGE_HOURS = 48

  def perform
    cutoff = max_age_hours.hours.ago
    [Shrine.storages[:submission_cache],
     Shrine.storages[:cache]].each do |cache|
      cache.clear! { |path| path.mtime < cutoff }
    end
  end

  private

    def max_age_hours
      hours = ENV.fetch("CACHE_MAX_AGE_HOURS", DEFAULT_MAX_AGE_HOURS).to_i
      hours.positive? ? hours : DEFAULT_MAX_AGE_HOURS
    end
end
