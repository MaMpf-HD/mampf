#!/usr/bin/env bash
cd /usr/src/app
if ! [ -f completed_initial_run ]
then
  echo 'Initialising mampf master container' &> >(tee -a /usr/src/app/log/initialisation.log)
  echo running: bundle exec rails db:migrate &> >(tee -a /usr/src/app/log/initialisation.log)
  bundle exec rails db:migrate &> >(tee -a /usr/src/app/log/initialisation.log)
  echo running: bundle exec rake sunspot:solr:reindex &> >(tee -a /usr/src/app/log/initialisation.log)
  bundle exec rake sunspot:solr:reindex &> >(tee -a /usr/src/app/log/initialisation.log)
  echo 'finished initialisation' &> >(tee -a /usr/src/app/log/initialisation.log)
  touch completed_initial_run
fi
echo "running mampf master"
exec bundle exec sidekiq &> >(tee -a /usr/src/app/log/runtime.log)
