#!/usr/bin/env bash
set -e
cd /usr/src/app/

./docker/init-dev-test.sh &> >(tee -a /usr/src/app/log/initialization.log)

echo "💫  Starting webpack server (in background)"
./bin/webpack-dev-server &

rm -f tmp/pids/server.pid
cp /pdfcomprezzor.wasm /wasm_exec.js public/pdfcomprezzor/
echo "Running MaMpf (in RAILS_ENV: $RAILS_ENV)"
bundle exec sidekiq &
prometheus_exporter --label "{\"container\": \"${HOSTNAME}\"}" -b 0.0.0.0 -p 9394 -a lib/collectors/mampf_collector.rb &> /usr/src/app/log/prometheus_exporter.log &!
exec bundle exec rails s -p 3000 -b '0.0.0.0' &> >(tee -a /usr/src/app/log/runtime.log)
