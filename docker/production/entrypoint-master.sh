#!/usr/bin/env bash
cd /usr/src/app
if ! [ -f completed_initial_run ]
then
  echo 'Initialising mampf master container'
  echo 'running: bundle exec rails db:migrate'
  bundle exec rails db:migrate
  echo 'running: bundle exec rake sunspot:solr:reindex'
  bundle exec rake sunspot:solr:reindex
  echo 'finished initialisation'
  touch completed_initial_run
fi
echo "running mampf master"
prometheus_exporter --label "{\"instance\": \"${HOSTNAME}\"}" -b 0.0.0.0 -p 9394 -a lib/collectors/mampf_collector.rb &> /usr/src/app/log/prometheus_exporter.log &!
exec bundle exec sidekiq &> >(tee -a /usr/src/app/log/runtime.log)