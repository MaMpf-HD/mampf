#!/usr/bin/env bash
set -e

cd /rails/
bundle exec rails db:migrate
# exec bundle exec sidekiq &> >(tee -a /rails/log/runtime.log)

echo "✨ Starting MaMpf web server ✨"
bundle exec rails s -p 3000 -b "0.0.0.0"
