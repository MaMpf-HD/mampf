#!/usr/bin/env bash

cd /usr/src/app
if ! [ -f completed_initial_run ]
then
  echo 'Initialising mampf' &> >(tee -a /usr/src/app/log/initialisation.log)
  echo running: bundle exec rails db:create &> >(tee -a /usr/src/app/log/initialisation.log)
  bundle exec rails db:create > /usr/src/app/log/initialisation.log
  echo running: bundle exec rails db:migrate &> >(tee -a /usr/src/app/log/initialisation.log)
  bundle exec rails db:migrate > /usr/src/app/log/initialisation.log
  echo running: bundle exec rails assets:precompile &> >(tee -a /usr/src/app/log/initialisation.log)
  bundle exec rails assets:precompile &> /usr/src/app/log/initialisation.log
  bundle exec rake sunspot:solr:reindex &
  echo 'finished initialisation' &> >(tee -a /usr/src/app/log/initialisation.log)
  touch completed_initial_run
fi
rm -f tmp/pids/server.pid
bin/rails server -e test -p 3000

# in separate window start cypress
yarn cypress open --project ./specs