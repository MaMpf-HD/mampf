#!/usr/bin/env bash
cd /usr/src/app

echo "Ensuring no stale server pid file is present"
rm -f tmp/pids/server.pid

echo "running mampf app"
prometheus_exporter --label "{\"container\": \"${HOSTNAME}\"}" -b 0.0.0.0 -p 9394 -a lib/collectors/mampf_collector.rb > /usr/src/app/log/prometheus_exporter.log 2>&1 &

exec bundle exec thrust ./bin/rails server \
  -p "${THRUSTER_TARGET_PORT:-3001}" -b ::