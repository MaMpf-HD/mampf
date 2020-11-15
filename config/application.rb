require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mampf
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.autoloader = :zeitwerk
    config.i18n.default_locale = :de
    config.i18n.fallbacks = [:en]
    config.i18n.available_locales = [:de, :en]
    config.time_zone = 'Berlin'
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.exception_handler = {
      email:      ENV['ERROR_EMAIL'], # sends exception emails to a listed email (string // "you@email.com")

      # All keys interpolated as strings, so you can use symbols, strings or integers where necessary
      exceptions: {

        all:  {
          layout: "application_no_sidebar", # define layout
          notification: true # (false by default)
        }
      }
    }
  end
end

