require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/memory" if Rails.env.test?

if Rails.env.development? || Rails.env == 'docker_development'
  Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
    store: Shrine::Storage::FileSystem.new("public", prefix: "uploads/store"),
    submission_cache: Shrine::Storage::FileSystem.new("public",
                                                prefix: "uploads/submissions/cache"),
    submission_store: Shrine::Storage::FileSystem.new("public",
                                                prefix: "uploads/submissions/store"),
  }
elsif Rails.env.production?
  Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new("/caches", prefix: "medien_uploads" ,clean:false),
    store: Shrine::Storage::FileSystem.new((ENV['MEDIA_PATH'] || '/private/media'),
                                           prefix: "/"),
    submission_cache: Shrine::Storage::FileSystem.new((ENV['SUBMISSION_PATH'] || '/private/submissions'),
                                                      prefix: "cache"),
    submission_store: Shrine::Storage::FileSystem.new((ENV['SUBMISSION_PATH'] || '/private/submissions'),
                                                      prefix: "store"),
  }
elsif Rails.env.test?
  Shrine.storages = {
    cache: Shrine::Storage::Memory.new,
    store: Shrine::Storage::Memory.new,
    submission_cache: Shrine::Storage::Memory.new,
    submission_store: Shrine::Storage::Memory.new
  }
end

Shrine.plugin :activerecord
# Shrine.plugin :determine_mime_type
Shrine.plugin :cached_attachment_data # for forms
# Shrine.plugin :restore_cached_data
Shrine.plugin :instrumentation

# use mv instead of cp when promoting files from cache to store
# Shrine.plugin :upload_options, cache: { move: !Rails.env.test? },
#                                store: { move: !Rails.env.test? }