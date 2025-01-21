#!/usr/bin/env bash
set -e

cd /usr/src/app
./initialize.sh &> >(tee -a /usr/src/app/log/initialisation.log)

rm -f tmp/pids/server.pid
cp /pdfcomprezzor.wasm /wasm_exec.js public/pdfcomprezzor/
echo "running mampf"
bundle exec sidekiq &
