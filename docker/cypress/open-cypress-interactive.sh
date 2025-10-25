#!/usr/bin/env bash
# set -e

# Wait for xpra at most 3 minutes
start=$SECONDS
until [ -S /tmp/.X11-unix/X79 ] || [ $((SECONDS - start)) -ge 180 ]; do
    echo "Waiting for X display :79..."
    sleep 1
done
if [ ! -S /tmp/.X11-unix/X79 ]; then
    echo "Timeout waiting for X display :79" >&2
    exit 1
fi

# TODO: wait for MaMpf container
# timeout 1m bash -c "
#     while ! curl -s $CYPRESS_baseUrl > /dev/null; do
#         echo waiting for MaMpf to come online at $CYPRESS_baseUrl;
#         sleep 1;
#     done
# ";

echo "Found xpra on display :79, will start cypress"

# https://on.cypress.io/command-line#cypress-open
# https://www.cypress.io/blog/2019/05/02/run-cypress-with-a-single-docker-command#Interactive-mode
DISPLAY=":79" RAILS_ENV="test" cypress open --project /mampf-tests/ --e2e --browser chrome
