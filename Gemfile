source "https://rubygems.org"
# We only pin versions to specific Git commits when they are "problem childs"
# and we want to review each commit before updating to the latest version.

ruby "3.3.8"

gem "active_model_serializers", "~> 0.10"
gem "activerecord-import", "~>1.7"
gem "activerecord-nulldb-adapter", "~> 1.0" # for assets precompilation in production
gem "active_storage_validations", "~> 2.0.2"
gem "acts_as_list", "~> 1.2"
gem "acts_as_tree", "~> 2.9"
gem "acts_as_votable", "~> 0.14"
gem "barby", "~> 0.6"
gem "bootsnap", "~> 1.18", require: false # reduces boot times through caching
gem "bootstrap", "~>5.3"
gem "bootstrap_form", "~> 5.4"
gem "cancancan", "~> 3.6"
gem "clipboard-rails", "~> 1.7"
gem "coffee-rails", "~> 5.0" # CoffeeScript for .coffee assets and views
gem "commontator", "~> 7.0.1"
gem "coveralls", "~> 0.7", require: false
gem "csv", "~> 3.3", require: false
gem "dalli", "~> 3.2" # caching to memcached in production
gem "devise", "~> 4.9"
gem "devise-bootstrap-views", "~> 1.1"
gem "erubis", "~> 2.7"
gem "exception_handler", "~> 0.8.0.0", "~> 0.8.0"
gem "faraday", "~> 1.8", "~> 1.10"
gem "fastimage", "~> 2.3"
gem "filesize", "~> 0.2"
gem "fuzzy-string-match", "~> 1.0"
gem "image_processing", "~> 1.13"
gem "jbuilder", "~> 2.12" # build JSON APIs easily
gem "jquery-rails", "~> 4.6"
gem "jquery-ui-rails", "~> 7.0"
gem "js-routes", "~> 2.3"
gem "kaminari", "~> 1.2"
gem "kaminari-i18n", "~> 0.5"
gem "kramdown-parser-gfm", "~> 1.1"
gem "mini_magick", "~> 4.13"
gem "mobility", "~> 1.2"
gem "net-smtp", "~> 0.5"
gem "pdf-reader", "~> 2.12"
gem "pg", "~> 1.5"
gem "premailer-rails", "~> 1.12"
gem "progress_bar", "~> 1.3"
gem "prometheus_exporter", "~> 2.1"
gem "puma", "~> 6.4" # app server
gem "rack", "~> 3.1"
gem "rails", "~> 8.0.2"
gem "rails-i18n", "~> 8.0"
gem "responders", "~> 3.1"
gem "rgl", "~> 0.6"
gem "rqrcode", "~> 2.2"
gem "rubyzip", "~> 2.3"
gem "sass-rails", "~> 6.0" # SCSS for stylesheets
gem "shrine", "~> 3.6"
gem "sidekiq", "~> 7.3"
gem "sidekiq-cron", "~> 1.12"
gem "sprockets-rails", "~>3.5"
gem "streamio-ffmpeg", "~> 3.0"
gem "sunspot_rails", "~> 2.7"
gem "sunspot_solr", "~> 2.7"
gem "terser", "~> 1.2" # Ruby wrapper for UglifyJS JavaScript compressor
gem "thredded", git: "https://github.com/thredded/thredded.git",
                ref: "566100f6a020ccc390aa60689d58b007a55506d2"
gem "thredded-markdown_katex",
    git: "https://github.com/thredded/thredded-markdown_katex.git",
    ref: "e2830bdb40880018a0e59d2b82c94b0a9f237365"
gem "trix-rails", "~> 2.4", require: "trix"
gem "turbolinks", "~> 5.2" # make navigating the app faster
gem "webpacker", "~> 5.4"

group :development do
  gem "listen", "~> 3.9"
  gem "marcel", "~> 1.0"
  gem "pgreset", "~> 0.4"
  gem "rails-erd", "~> 1.7"
  gem "rubocop", "~> 1.65", require: false
  gem "rubocop-performance", "~> 1.21", require: false
  gem "rubocop-rails", "~> 2.24", require: false
  gem "spring", "~> 4.3" # app preloader, keeps app running in background for development
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 4.2" # interactive console on exception pages
end

group :test do
  gem "database_cleaner-active_record", "~> 2.2" # clean up database between tests
  gem "faker", "~> 3.4"
  gem "simplecov", "~> 0.22", require: false
  gem "timecop", "~> 0.9.10"
end

group :development, :test do
  gem "debug", "~> 1.8"
  gem "factory_bot_rails", "~> 6.4"
  gem "i18n-tasks", "~> 1.0.15"
  gem "rspec-github", "~> 2.4"
  gem "rspec-rails", "~> 6.1"
  gem "simplecov-cobertura", "~> 2.1"
end
