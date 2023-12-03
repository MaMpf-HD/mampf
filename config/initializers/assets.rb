# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
Rails.application.config.assets.precompile += ["thredded_katex.scss"]
Rails.application.config.assets.precompile += ["thredded_timeago.js"]
Rails.application.config.assets.precompile += ["show_clicker_assets.js"]
Rails.application.config.assets.precompile += ["edit_clicker_assets.js"]

# fix concurrency issue that leads to occasional seg fault
# See https://github.com/sass/sassc-ruby/issues/207
if Rails.env.test?
  Rails.application.configure do
    config.assets.configure do |env|
      env.export_concurrent = false
    end
  end
end

# Allow overriding of the sprockets cache path
# This is done to fix this problem:
# (https://github.com/rails/sprockets/issues/283#issuecomment-578728257)
if Rails.env.docker_development? # rubocop:todo Rails/UnknownEnv
  Rails.application.config.assets.configure do |env|
    env.cache = Sprockets::Cache::FileStore.new(
      ENV.fetch("SPROCKETS_CACHE", "#{env.root}/tmp/cache/assets"),
      Rails.application.config.assets.cache_limit,
      env.logger
    )
  end
end
