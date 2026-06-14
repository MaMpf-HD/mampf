#!/usr/bin/env bash
set -Eeuo pipefail

umask 027
cd /usr/src/app

bundle exec prometheus_exporter \
  --label "{\"container\": \"${HOSTNAME:-unknown}\"}" \
  -b 0.0.0.0 \
  -p 9394 \
  -a lib/collectors/mampf_collector.rb &
prometheus_exporter_pid=$!

cleanup() {
  kill "$prometheus_exporter_pid" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

exec bundle exec sidekiq