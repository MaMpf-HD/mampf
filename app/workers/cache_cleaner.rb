class CacheCleaner
  include Sidekiq::Worker

  def perform
    submission_cache = Shrine.storages[:submission_cache]
    media_cache = Shrine.storages[:cache]
    submission_cache.clear! { |path| path.mtime < 1.week.ago }
    media_cache.clear! { |path| path.mtime < 1.week.ago }
  end
end
