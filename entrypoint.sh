#!/usr/bin/env bash
set -e

# export GEM_HOME=""
# export BUNDLE_SILENCE_ROOT_WARNING=""

# unset BUNDLE_PATH
# unset BUNDLE_BIN

# ln -s /usr/local/bundle/ruby/3.1.0/gems /usr/local/bundle/ruby/3.1.0/bundler/gems

# touch /usr/local/bundle/ruby/3.1.0/bundler/gems/thredded-1340e913affd

# echo "Check that file exists"
# ls -l /usr/local/bundle/ruby/3.1.0/bundler/gems/

# bundle config set path '/usr/local/bundle'

# echo "🕳 Running bundle config"
# bundle config

# echo "🕳 Running bundle check"
# bundle check

cd /usr/src/app

./initialize.sh &> >(tee -a /usr/src/app/log/initialisation.log)

rm -f tmp/pids/server.pid
cp /pdfcomprezzor.wasm /wasm_exec.js public/pdfcomprezzor/
echo "running mampf"
bundle exec sidekiq &
