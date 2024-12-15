require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mampf
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults(7.1)
    config.autoloader = :zeitwerk

    # Autoload subfolders of modules (recursively)
    # https://stackoverflow.com/a/4794775/
    additional_paths = Rails.root.glob("app/models/voucher/")
    config.autoload_paths += additional_paths
    config.eager_load_paths += additional_paths

    # Autoload lib extensions path
    config.autoload_lib(ignore: ["assets", "collectors", "core_ext", "scrapers", "tasks"])

    config.i18n.default_locale = :de
    config.i18n.fallbacks = [:en]
    config.i18n.available_locales = [:de, :en]
    config.i18n.raise_on_missing_translations = false
    config.time_zone = "Berlin"

    # Message serializing. Starting with Rails 7.2, the default is :json.
    # See: https://guides.rubyonrails.org/v7.1/configuring.html#config-active-support-message-serializer
    Rails.application.config.active_support.message_serializer = :json

    # Make `form_with` generate remote forms by default.
    config.action_view.form_with_generates_remote_forms = true
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.exception_handler = {
      # sends exception emails to a listed email (string // "you@email.com")
      email: ENV.fetch("ERROR_EMAIL"),

      # All keys interpolated as strings, so you can use
      # symbols, strings or integers where necessary
      exceptions: {
        all: {
          layout: "application_no_sidebar", # define layout
          notification: true # (false by default)
        }
      }
    }
    config.to_prepare do
      # some monkey patches for sidekiq-cron
      # see https://github.com/ondrejbartas/sidekiq-cron/issues/310
      Sidekiq::Cron::Job.class_eval do
        def self.all
          job_hashes = nil
          Sidekiq.redis do |conn|
            set_members = conn.smembers(jobs_key)
            job_hashes = conn.pipelined do |pipeline|
              set_members.each do |key|
                pipeline.hgetall(key)
              end
            end
          end
          job_hashes.compact.reject(&:empty?).collect do |h|
            # no need to fetch missing args from redis since we just got
            # this hash from there
            Sidekiq::Cron::Job.new(h.merge(fetch_missing_args: false))
          end
        end
      end
    end
    # Make sure that our custom commontator controllers are loaded
    # instead of the default ones
    # see https://github.com/lml/commontator/issues/200#issuecomment-1231456146
    Commontator::Engine.config.autoload_once_paths = []
  end
end
