source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 6.0.3"
# Use dalli for caching to memcached in production
gem "dalli", ">= 2.7"
# Ruby wrapper for UglifyJS JavaScript compressor
gem "uglifier"
# Use nulldb adapter for assets precompilation in production
gem "activerecord-nulldb-adapter"
# Use sqlite3 as the database for Active Record
gem "sqlite3", "~> 1.4"
# Use Puma as the app server
gem "puma", "~> 4.1"
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
gem "bootsnap", ">= 1.4.2", require: false
gem "rack"
gem "active_model_serializers"
# Use CoffeeScript for .coffee assets and views
gem "coffee-rails", "~> 5.0.0"

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
gem "shrine"
gem "fastimage"
gem "streamio-ffmpeg"
gem "pdf-reader"
gem "mini_magick"
gem "image_processing"
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
gem "filesize"
# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
gem "rgl"
gem "responders"
gem "pg"
gem "devise"
gem "erubis"
gem "cancancan"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "js-routes"
gem "bootstrap"
gem "bootstrap_form"
gem "devise-bootstrap-views"
gem "fuzzy-string-match"
gem "coveralls", require: false
gem "kaminari"
gem "selectize-rails"
gem "acts_as_list"
gem "acts_as_tree"
gem "activerecord-import",
  git: "https://github.com/zdennis/activerecord-import.git",
  branch: "master"
gem "thredded",
  git: "https://github.com/fosterfarrell9/thredded",
  branch: "master"
gem "kramdown-parser-gfm"
gem "thredded-markdown_katex"
gem "rails-i18n"
gem "kaminari-i18n"
gem "trix-rails", require: "trix"
gem "xkcd"
gem "sunspot_rails"
gem "sunspot_solr"
gem "progress_bar"
gem "barby"
gem "rqrcode"
gem "sidekiq"
gem "faraday"
gem "globalize"
gem "globalize-accessors"
gem "commontator",
  git: "https://github.com/fosterfarrell9/commontator",
  branch: "master"
gem "acts_as_votable"
gem "sprockets-rails",
  git: "https://github.com/rails/sprockets-rails",
  branch: "master"
gem "premailer-rails"
gem "select2-rails"
gem "clipboard-rails"
gem "rubyzip"
gem "exception_handler", "~> 0.8.0.0"
gem 'webpacker', '~> 5.x'

group :development, :docker_development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "rspec-rails"
  gem "factory_bot_rails"
end

group :development, :docker_development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 3.3.0"
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "rails-erd"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "rubocop", "~> 0.93", require: false
  gem "rubocop-packaging", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "erb_lint", require: false
  gem "pgreset"
  gem "marcel"
  #  gem 'bullet'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "selenium-webdriver"
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
  gem 'faker'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'simplecov', require: false
end

group :test, :development, :docker_development do
  gem 'cypress-on-rails', '~> 1.0'
end
