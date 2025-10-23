#!/usr/bin/env bash
# For usage in the CI/CD pipeline (GitHub Actions)

set -e

timeout 2m bash -c "
    while ! curl -s $CYPRESS_baseUrl > /dev/null; do
        echo waiting for MaMpf to come online at $CYPRESS_baseUrl;
        sleep 1;
    done
";

RAILS_ENV="test" cypress run --project /mampf-tests/ --e2e --browser chrome
