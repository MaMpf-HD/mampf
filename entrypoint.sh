#!/usr/bin/env bash

cd /usr/src/app

./initialize.sh &> >(tee -a /usr/src/app/log/initialisation.log)

rm -f tmp/pids/server.pid
cp /pdfcomprezzor.wasm public/pdfcomprezzor/pdfcomprezzor.wasm
echo "running mampf"
bundle exec sidekiq &
prometheus_exporter --label "{\"container\": \"${HOSTNAME}\"}" -b 0.0.0.0 -p 9394 -a lib/collectors/mampf_collector.rb &!
exec bundle exec rails s -p 3000 -b '0.0.0.0' &> >(tee -a /usr/src/app/log/runtime.log)
