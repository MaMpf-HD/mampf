#!/usr/bin/env bash
echo "Initialising mampf"
cd /usr/src/app
if ! [ -f /completed_initial_run ]
then
  echo running: bundle exec rails db:migrate
  bundle exec rails db:migrate
  echo running: bundle exec rails assets:precompile
  bundle exec rails assets:precompile
  touch /completed_initial_run
fi
rm -f tmp/pids/server.pid
echo "running mampf"
exec bundle exec rails s -p 3000 -b '0.0.0.0' > >(tee -a /usr/src/app/log/stdout.log) 2> >(tee -a /usr/src/app/log/stderr.log >&2)
