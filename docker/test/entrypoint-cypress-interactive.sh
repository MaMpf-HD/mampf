#!/usr/bin/env bash
set -e

timeout 1m bash -c '
    while ! curl -s $CYPRESS_baseUrl > /dev/null; do
        echo waiting for MaMpf to come online at $CYPRESS_baseUrl;
        sleep 1;
    done
';

# https://on.cypress.io/command-line#cypress-open
RAILS_ENV=test cypress open --project /mampf-tests/ --e2e --browser chrome
