#!/usr/bin/env bash
set -e
cd /usr/src/app/

./docker/init-dev-test.sh &> >(tee -a /usr/src/app/log/initialization.log)

bundle exec rake js:recompile_routes
echo "💫  Starting Vite dev server (in background)"
bundle exec vite dev &

rm -f tmp/pids/server.pid
cp /pdfcomprezzor.wasm /wasm_exec.js public/pdfcomprezzor/

echo ""
echo ""
echo "----------------------------------------------------"
echo "Running MaMpf (in RAILS_ENV: $RAILS_ENV)"
echo "----------------------------------------------------"
bundle exec sidekiq &
# prometheus_exporter --label "{\"container\": \"${HOSTNAME}\"}" -b 0.0.0.0 -p 9394 -a lib/collectors/mampf_collector.rb &> /usr/src/app/log/prometheus_exporter.log &!

# https://shopify.github.io/ruby-lsp/vscode-extension.html#debugging-live-processes
# https://marketplace.visualstudio.com/items?itemName=KoichiSasada.vscode-rdbg
RUBY_DEBUG_OPEN=true RUBY_DEBUG_NONSTOP=true RUBY_DEBUG_HOST="0.0.0.0" RUBY_DEBUG_PORT=13254 bundle exec bin/rails s -p "$MAMPF_PORT" -b '0.0.0.0' &> >(tee -a /usr/src/app/log/runtime.log)
