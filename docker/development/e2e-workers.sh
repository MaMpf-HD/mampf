#!/usr/bin/env bash
# Prints the number of parallel Playwright workers: 60% of the cores, rounded
# (each worker runs a browser and a Rails server). Override via E2E_WORKERS.
# Keep in sync with e2e/_support/servers.ts.
default_workers=$((($(nproc) * 6 + 5) / 10))
echo "${E2E_WORKERS:-$((default_workers > 1 ? default_workers : 1))}"
