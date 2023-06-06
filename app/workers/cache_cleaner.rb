class CacheCleaner
  include Sidekiq::Worker

  def perform
    submission_cache = Shrine.storages[:submission_cache]
    media_cache = Shrine.storages[:cache]
    submission_cache.clear! { |path| path.mtime < Time.now - 1.week }
    media_cache.clear! { |path| path.mtime < Time.now - 1.week }
  end
end
