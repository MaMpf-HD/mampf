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
for port in $ports_to_clean; do
	# adapted from https://stackoverflow.com/a/9168553/
    pid=$(lsof -ti:$port) || true
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

rm -f tmp/pids/server.pid

echo ""
echo ""
echo "----------------------------------------------------"
echo "Running MaMpf (in RAILS_ENV: $RAILS_ENV)"
echo "----------------------------------------------------"
bundle exec sidekiq &
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
