#!/bin/bash
set -e

if [ ! -S /var/run/docker-host.sock ]; then
  exit 0
fi

proxy_pid_file=/tmp/mampf-docker-proxy.pid
proxy_pattern='socat UNIX-LISTEN:/var/run/docker.sock.*UNIX-CONNECT:/var/run/docker-host.sock'

if [ -f "$proxy_pid_file" ] && ps -p "$(cat "$proxy_pid_file")" > /dev/null 2>&1; then
  exit 0
fi

sudo pkill -f "$proxy_pattern" 2>/dev/null || true
sudo rm -f /var/run/docker.sock

(sudo socat \
  UNIX-LISTEN:/var/run/docker.sock,fork,mode=660,user="$(id -un)",group="$(id -gn)",backlog=128 \
  UNIX-CONNECT:/var/run/docker-host.sock \
  2>&1 | sudo tee /tmp/mampf-docker-proxy.log > /dev/null & echo "$!" | sudo tee "$proxy_pid_file" > /dev/null)