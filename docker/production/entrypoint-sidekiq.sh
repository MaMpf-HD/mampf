#!/usr/bin/env bash
set -Eeuo pipefail

umask 027
cd /usr/src/app

bundle exec prometheus_exporter \
  --label "{\"container\": \"${HOSTNAME:-unknown}\"}" \
  -b 0.0.0.0 \
  -p 9394 &

exec bundle exec sidekiq