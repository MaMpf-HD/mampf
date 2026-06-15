#!/usr/bin/env bash
set -Eeuo pipefail

umask 027
cd /usr/src/app

mkdir -p tmp/pids
rm -f tmp/pids/server.pid

bundle exec prometheus_exporter \
  --label "{\"container\": \"${HOSTNAME:-unknown}\"}" \
  -b 0.0.0.0 \
  -p 9394 \
  -a lib/collectors/mampf_collector.rb &

exec bundle exec thrust ./bin/rails server \
  -p "${THRUSTER_TARGET_PORT:-3001}" -b ::