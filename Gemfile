source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.4"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 7.1.3"
# Use dalli for caching to memcached in production
gem "dalli", ">= 2.7"
# Ruby wrapper for UglifyJS JavaScript compressor
gem "terser"
# Use nulldb adapter for assets precompilation in production
gem "activerecord-nulldb-adapter"
# Use sqlite3 as the database for Active Record
gem "sqlite3", "~> 1.4"
# Use Puma as the app server
gem "puma", "< 7"
# Use SCSS for stylesheets
gem "sass-rails", ">= 6"
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
# gem 'webpacker', '~> 4.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem "active_model_serializers"
gem "bootsnap", ">= 1.4.2", require: false
gem "rack", "<3"
# Use CoffeeScript for .coffee assets and views
gem "coffee-rails", "~> 5.0.0"

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
gem "fastimage"
gem "image_processing"
gem "mini_magick"
gem "pdf-reader"
gem "shrine"
gem "streamio-ffmpeg"
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
gem "filesize"
# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
gem "activerecord-import",
    git: "https://github.com/zdennis/activerecord-import.git",
    branch: "master"
gem "acts_as_list"
gem "acts_as_tree"
gem "acts_as_votable"
gem "barby"
gem "bootstrap", "~>5"
gem "bootstrap_form"
gem "cancancan"
gem "clipboard-rails"
gem "commontator"
gem "coveralls", require: false
gem "devise"
gem "devise-bootstrap-views"
gem "erubis"
gem "exception_handler", "~> 0.8.0.0"
gem "faraday", "~> 1.8"
gem "fuzzy-string-match"
gem "html-pipeline", "~> 2.14"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "js-routes", "1.4.9"
gem "kaminari"
gem "kaminari-i18n"
gem "kramdown-parser-gfm"
gem "mobility"
gem "net-smtp"
gem "pg"
gem "premailer-rails"
gem "progress_bar"
gem "rails-i18n"
gem "responders"
gem "rgl"
gem "rqrcode"
gem "rubyzip", "~> 2.3.0"
gem "sidekiq"
gem "sidekiq-cron", "~> 1.1"
gem "sprockets-rails",
    git: "https://github.com/rails/sprockets-rails",
    branch: "master"
gem "sunspot_rails",
    github: "sunspot/sunspot",
    glob: "sunspot_rails/*.gemspec"
gem "sunspot_solr"
gem "thredded"
gem "thredded-markdown_katex",
    git: "https://github.com/thredded/thredded-markdown_katex.git",
    branch: "main"
gem "trix-rails", require: "trix"
gem "webpacker", "~> 5.x"

group :development, :docker_development do
  gem "listen", "~> 3.9"
  gem "rails-erd"
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 3.3.0"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "marcel"
  gem "pgreset"
  gem "rubocop", "~> 1.63", require: false
  gem "rubocop-performance", "~> 1.21", require: false
  gem "rubocop-rails", "~> 2.24", require: false
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  #  gem 'bullet'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "selenium-webdriver"
  # Easy installation and use of web drivers to run system tests with browsers
  gem "database_cleaner"
  gem "faker"
  gem "launchy"
  gem "simplecov", require: false
  gem "webdrivers"
end

group :test, :development, :docker_development do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "factory_bot_rails"
  gem "rspec-rails"

  gem "cypress-on-rails", "~> 1.0"
  gem "simplecov-cobertura"
end

gem "prometheus_exporter"
