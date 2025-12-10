#!/usr/bin/env bash
set -e

cd /usr/src/app
bundle exec rails db:migrate
# exec bundle exec sidekiq &> >(tee -a /usr/src/app/log/runtime.log)

echo "✨ Starting MaMpf web server ✨"
bundle exec rails s -p 3000 -b "0.0.0.0"
