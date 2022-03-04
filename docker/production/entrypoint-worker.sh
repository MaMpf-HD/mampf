#!/usr/bin/env bash
cd /usr/src/app
echo "Ensuring no stale server pid file is present"
rm -f tmp/pids/server.pid
echo "running mampf"
prometheus_exporter --label "{\"instance\": \"${HOSTNAME}\"}" -b 0.0.0.0 -p 9394 -a lib/collectors/mampf_collector.rb &> /usr/src/app/log/prometheus_exporter.log &!
exec bundle exec rails s -p 3000 -b '0.0.0.0'
