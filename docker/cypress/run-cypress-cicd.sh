#!/usr/bin/env bash
set -e

# For usage in the CI/CD pipeline (GitHub Actions)

# Wait for MaMpf container
start_app=$SECONDS
while ! curl -sS "$CYPRESS_baseUrl" >/dev/null; do
    if [ $((SECONDS - start_app)) -ge 120 ]; then
        echo "Timeout waiting for MaMpf at $CYPRESS_baseUrl" >&2
        exit 1
    fi
    echo "Waiting (at most 2 minutes) for MaMpf to come online at $CYPRESS_baseUrl ..."
    sleep 1
done

echo "✨ Found MaMpf test app running, will now start Cypress"

RAILS_ENV="test" cypress run --project /mampf-tests/ --e2e --browser chrome
