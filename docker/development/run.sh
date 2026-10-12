#!/usr/bin/env bash
set -Eeuo pipefail
cd /workspaces/mampf/

public_http_port="${APP_HEALTHCHECK_PORT:-${THRUSTER_HTTP_PORT:-}}"

echo "RAILS_ENV: $RAILS_ENV"
echo "NODE_ENV: $NODE_ENV"
[ "$RAILS_ENV" != "$NODE_ENV" ] && echo "Error: RAILS_ENV and NODE_ENV must be the same!" && exit 1

echo "🧹 Cleaning up stale Vite/Debugger port processes..."
ports_to_clean="3036 13254"
if [ -n "${THRUSTER_HTTP_PORT:-}" ]; then
	ports_to_clean="$ports_to_clean $public_http_port ${THRUSTER_TARGET_PORT:-3001}"
fi
if [ "$RAILS_ENV" = "test" ]; then
	ports_to_clean="$ports_to_clean 3145"
fi

# Extra app servers for parallel Playwright workers: worker i gets its own
# ports (offset by 10 * i) and its own test database ("_e2e<i>" suffix).
# Keep the ports in sync with e2e/_support/servers.ts.
e2e_workers=$(./docker/development/e2e-workers.sh)
extra_e2e_workers=""
if [ "$RAILS_ENV" = "test" ] && [ -n "${THRUSTER_HTTP_PORT:-}" ]; then
	extra_e2e_workers=$(seq 1 $((e2e_workers - 1)))
fi
for i in $extra_e2e_workers; do
	ports_to_clean="$ports_to_clean $((public_http_port + 10 * i)) $((THRUSTER_TARGET_PORT + 10 * i))"
done
for port in $ports_to_clean; do
	# adapted from https://stackoverflow.com/a/9168553/
    pid=$(lsof -ti:"$port") || true
    if [ -n "$pid" ]; then
		echo "Killing process $pid on port $port"
        kill -TERM "$pid" || kill -KILL "$pid" || true
    fi
done

bundle exec rake js:recompile_routes

if [ "${DISABLE_VITE_IN_CI:-}" != "true" ]; then
	echo "💫  Starting Vite dev server (in background)"
	bundle exec vite dev &
else
	echo "Vite dev server disabled due to DISABLE_VITE_IN_CI=true"
fi

rm -f tmp/pids/server.pid tmp/pids/server_e2e*.pid

echo ""
echo ""
echo "----------------------------------------------------"
echo "Running MaMpf (in RAILS_ENV: $RAILS_ENV)"
echo "----------------------------------------------------"
bundle exec sidekiq &

for i in $extra_e2e_workers; do
	worker_http_port=$((public_http_port + 10 * i))
	worker_target_port=$((THRUSTER_TARGET_PORT + 10 * i))
	worker_storage_path="${THRUSTER_STORAGE_PATH:-/cache/thruster-test}-e2e$i"
	mkdir -p "$worker_storage_path"
	echo "Starting Playwright worker server $i on port $worker_http_port (log/runtime_e2e$i.log)"
	TEST_ENV_NUMBER="_e2e$i" \
		MAMPF_PORT="$worker_target_port" \
		THRUSTER_HTTP_PORT="$worker_http_port" \
		THRUSTER_TARGET_PORT="$worker_target_port" \
		THRUSTER_STORAGE_PATH="$worker_storage_path" \
		bundle exec thrust bin/rails s -b '0.0.0.0' -P "tmp/pids/server_e2e$i.pid" \
		&> "/workspaces/mampf/log/runtime_e2e$i.log" &
done
# prometheus_exporter --label "{\"container\": \"${HOSTNAME}\"}" -b 0.0.0.0 -p 9394 -a lib/collectors/mampf_collector.rb &> /workspaces/mampf/log/prometheus_exporter.log &!

# https://shopify.github.io/ruby-lsp/vscode-extension.html#debugging-live-processes
# https://marketplace.visualstudio.com/items?itemName=KoichiSasada.vscode-rdbg
if [ -n "${THRUSTER_HTTP_PORT:-}" ]; then
	if [ -n "${THRUSTER_STORAGE_PATH:-}" ]; then
		mkdir -p "$THRUSTER_STORAGE_PATH"
	fi
	echo "Starting Thruster on port $public_http_port with Rails on ${THRUSTER_TARGET_PORT:-3001}"
	RUBY_DEBUG_ENABLE="${RUBY_DEBUG_ENABLE:-}" RUBY_DEBUG_OPEN=true RUBY_DEBUG_NONSTOP=true RUBY_DEBUG_HOST="0.0.0.0" RUBY_DEBUG_PORT=13254 bundle exec thrust bin/rails s -b '0.0.0.0' &> >(tee -a /workspaces/mampf/log/runtime.log)
else
	RUBY_DEBUG_ENABLE="${RUBY_DEBUG_ENABLE:-}" RUBY_DEBUG_OPEN=true RUBY_DEBUG_NONSTOP=true RUBY_DEBUG_HOST="0.0.0.0" RUBY_DEBUG_PORT=13254 bundle exec bin/rails s -p "$MAMPF_PORT" -b '0.0.0.0' &> >(tee -a /workspaces/mampf/log/runtime.log)
fi
