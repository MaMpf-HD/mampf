#!/usr/bin/env bash
# Creates the test databases for the extra Playwright workers and loads the
# schema into them (rerun after new migrations).
#
# Worker 0 uses the regular test database. Worker i (i >= 1) uses the suffix
# "_e2e<i>", e.g. "mampf-test_e2e1", which never clashes with the numeric
# suffixes of the parallel RSpec workers ("mampf-test1", ...).
set -Eeuo pipefail
cd /workspaces/mampf/

# 60% of the cores, rounded (each worker runs a browser and a Rails server).
# Override via E2E_WORKERS. Keep in sync with e2e/_support/servers.ts.
default_workers=$((($(nproc) * 6 + 5) / 10))
e2e_workers="${E2E_WORKERS:-$((default_workers > 1 ? default_workers : 1))}"

pids=()
for i in $(seq 1 $((e2e_workers - 1))); do
	echo "🛠️  Preparing test database for Playwright worker $i"
	RAILS_ENV=test TEST_ENV_NUMBER="_e2e$i" bundle exec rails db:create db:schema:load &
	pids+=("$!")
done
for pid in "${pids[@]}"; do
	wait "$pid"
done
