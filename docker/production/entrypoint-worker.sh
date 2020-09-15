#!/usr/bin/env bash
cd /usr/src/app
echo "Ensuring no stale server pid file is present"
rm -f tmp/pids/server.pid
echo "running mampf"
exec bundle exec rails s -p 3000 -b '0.0.0.0'
