require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/memory" if Rails.env.test?

if Rails.env.development?
  Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
    store: Shrine::Storage::FileSystem.new("public", prefix: "uploads/store"),
  }
elsif Rails.env.production?
  Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
    store: Shrine::Storage::FileSystem.new("/" + (ENV['MEDIA_FOLDER'] || 'mampf'), prefix: "/"),
  }
elsif Rails.env.test?
  Shrine.storages = {
    cache: Shrine::Storage::Memory.new,
    store: Shrine::Storage::Memory.new,
  }
end

Shrine.plugin :activerecord
Shrine.plugin :determine_mime_type
Shrine.plugin :cached_attachment_data # for forms
Shrine.plugin :restore_cached_data
Shrine.plugin :instrumentation
Shrine.plugin :upload_endpoint
