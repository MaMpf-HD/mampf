#!/usr/bin/env bash
set -e

# Wait for xpra at most 60s by attempting an actual X11 connection
start=$SECONDS

# prefer xdpyinfo, fallback to xset
if command -v xdpyinfo >/dev/null 2>&1; then
    check_cmd() { DISPLAY=":79" xdpyinfo >/dev/null 2>&1; }
elif command -v xset >/dev/null 2>&1; then
    check_cmd() { DISPLAY=":79" xset q >/dev/null 2>&1; }
else
    echo "Missing X11 client (xdpyinfo/xset). Install x11-utils or x11-xserver-utils." >&2
    exit 1
fi

while ! check_cmd; do
    if [ $((SECONDS - start)) -ge 60 ]; then
        echo "Timeout waiting for X display :79" >&2
        exit 1
    fi
    echo "Waiting (at most 60s) for X display :79 to be ready ..."
    sleep 1
done

echo "✨ Found xpra on display :79"

# Wait for MaMpf container
start_app=$SECONDS
while ! curl -sSf "$CYPRESS_baseUrl" >/dev/null 2>&1; do
    if [ $((SECONDS - start_app)) -ge 60 ]; then
        echo "Timeout waiting for MaMpf at $CYPRESS_baseUrl" >&2
        exit 1
    fi
    echo "Waiting (at most 60s) for MaMpf to come online at $CYPRESS_baseUrl ..."
    sleep 1
done

echo "✨ Found MaMpf test app running, will now start Cypress"

# https://on.cypress.io/command-line#cypress-open
# https://www.cypress.io/blog/2019/05/02/run-cypress-with-a-single-docker-command#Interactive-mode
DISPLAY=":79" RAILS_ENV="test" cypress open --project /mampf-tests/ --e2e --browser chrome
