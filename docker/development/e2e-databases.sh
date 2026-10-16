#!/usr/bin/env bash
# Creates the test databases for the Playwright workers and loads the schema
# into them (rerun after new migrations).
#
# Worker i uses the suffix "_e2e<i>", e.g. "mampf-test_e2e0", which never
# clashes with the regular test database of RSpec ("mampf-test") or the
# numeric suffixes of the parallel RSpec workers ("mampf-test1", ...).
set -Eeuo pipefail
cd /workspaces/mampf/

e2e_workers=$(./docker/development/e2e-workers.sh)

pids=()
for i in $(seq 0 $((e2e_workers - 1))); do
	echo "🛠️  Preparing test database for Playwright worker $i"
	RAILS_ENV=test TEST_ENV_NUMBER="_e2e$i" bundle exec rails db:create db:schema:load &
	pids+=("$!")
done
for pid in "${pids[@]}"; do
	wait "$pid"
done
