#!/usr/bin/env bash
# Succeeds once the app servers of all Playwright workers answer
# (see docker/development/run.sh).
set -Eeuo pipefail

e2e_workers=$(/workspaces/mampf/docker/development/e2e-workers.sh)
for i in $(seq 0 $((e2e_workers - 1))); do
	curl --fail --silent --output /dev/null "http://localhost:$((APP_HEALTHCHECK_PORT + 10 * i))"
done
