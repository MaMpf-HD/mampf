source "https://rubygems.org"

ruby "3.1.4"

gem "active_model_serializers"
gem "activerecord-import", "~>1.7"
gem "activerecord-nulldb-adapter" # for assets precompilation in production
gem "acts_as_list"
gem "acts_as_tree"
gem "acts_as_votable"
gem "barby"
gem "bootsnap", "~> 1.18", require: false # reduces boot times through caching
gem "bootstrap", "~>5"
gem "bootstrap_form"
gem "cancancan"
gem "clipboard-rails"
gem "coffee-rails", "~> 5.0.0" # CoffeeScript for .coffee assets and views
gem "commontator"
gem "coveralls", require: false
gem "dalli", "~> 3.2" # caching to memcached in production
gem "devise"
gem "devise-bootstrap-views"
gem "erubis"
gem "exception_handler", "~> 0.8.0.0"
gem "faraday", "~> 1.8"
gem "fastimage"
gem "filesize"
gem "fuzzy-string-match"
gem "image_processing"
gem "jbuilder" # build JSON APIs easily
gem "jquery-rails"
gem "jquery-ui-rails"
gem "js-routes", "1.4.9"
gem "kaminari"
gem "kaminari-i18n"
gem "kramdown-parser-gfm"
gem "mini_magick"
gem "mobility"
gem "net-smtp"
gem "pdf-reader"
gem "pg"
gem "premailer-rails"
gem "progress_bar"
gem "prometheus_exporter"
gem "puma", "< 7" # app server
gem "rack", "<3"
gem "rails", "~> 7.1.3"
gem "rails-i18n"
gem "responders"
gem "rgl"
gem "rqrcode"
gem "rubyzip", "~> 2.3.0"
gem "sass-rails", "~> 6.0" # SCSS for stylesheets
gem "shrine"
gem "sidekiq"
gem "sidekiq-cron", "~> 1.1"
gem "sprockets-rails", "~>3.5"
gem "sqlite3", "~> 1.4" # database for ActiveRecord
gem "streamio-ffmpeg"
gem "sunspot_rails", "~> 2.7"
gem "sunspot_solr"
gem "terser" # Ruby wrapper for UglifyJS JavaScript compressor
gem "thredded", git: "https://github.com/thredded/thredded.git",
                ref: "1340e913affd1af5fcc060fbccd271184ece9a6a"
gem "thredded-markdown_katex",
    git: "https://github.com/thredded/thredded-markdown_katex.git",
    ref: "e2830bdb40880018a0e59d2b82c94b0a9f237365"
gem "trix-rails", require: "trix"
gem "turbolinks", "~> 5" # make navigating the app faster
gem "webpacker", "~> 5.x"

group :development, :docker_development do
  gem "listen", "~> 3.9"
  gem "marcel"
  gem "pgreset"
  gem "rails-erd"
  gem "rubocop", "~> 1.63", require: false
  gem "rubocop-performance", "~> 1.21", require: false
  gem "rubocop-rails", "~> 2.24", require: false
  gem "spring" # app preloader, keeps app running in background for development
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "web-console", "~> 4.2" # interactive console on exception pages
end

group :test do
  gem "database_cleaner-active_record" # clean up database between tests
  gem "faker"
  gem "launchy"
  gem "selenium-webdriver" # support for Capybara system testing and selenium driver
  gem "simplecov", require: false
  gem "webdrivers"
end

group :test, :development, :docker_development do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "factory_bot_rails"
  gem "rspec-github"
  gem "rspec-rails"
  gem "simplecov-cobertura"
end
