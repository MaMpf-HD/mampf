#!/usr/bin/env bash
set -e

cd /usr/src/app
./initialize.sh &> >(tee -a /usr/src/app/log/initialisation.log)

echo "💫  Starting webpack server (in background)"
./bin/webpack-dev-server &

rm -f tmp/pids/server.pid
cp /pdfcomprezzor.wasm /wasm_exec.js public/pdfcomprezzor/
echo "running mampf"
bundle exec sidekiq &
exec bundle exec rails s -p 3000 -b '0.0.0.0' &> >(tee -a /usr/src/app/log/runtime.log)
