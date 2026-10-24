#!/usr/bin/env bash
# Computes the number of Playwright workers and writes it to tmp/e2e-workers,
# the single source of truth for init.sh, run.sh, e2e-databases.sh, the
# healthcheck and Playwright.
#
# Default: 60% of the cores, rounded (each worker runs a browser and a Rails
# server). Override via E2E_WORKERS.
set -Eeuo pipefail
cd "$(dirname "$0")/../.."

default_e2e_workers=$((($(nproc) * 6 + 5) / 10))
e2e_workers="${E2E_WORKERS:-$((default_e2e_workers > 1 ? default_e2e_workers : 1))}"
mkdir -p tmp
echo "$e2e_workers" > tmp/e2e-workers
