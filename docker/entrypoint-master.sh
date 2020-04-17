#!/usr/bin/env bash
cd /usr/src/app
if ! [ -f completed_initial_run ]
then
  echo 'Initialising mampf master container'
  echo 'running: bundle exec rails db:migrate'
  bundle exec rails db:migrate
  echo 'running: bundle exec rake sunspot:solr:reindex'
  bundle exec rake sunspot:solr:reindex
  echo 'copying public assets to volume'
  rsync -av --delete public/ /public/
  echo 'finished initialisation'
  touch completed_initial_run
fi
echo "running mampf master"
exec bundle exec sidekiq &> >(tee -a /usr/src/app/log/runtime.log)
