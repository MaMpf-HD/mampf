#!/usr/bin/env bash
cd /usr/src/app
if ! [ -f completed_initial_run ]
then
  echo 'Initialization mampf master container'
  echo 'running: bundle exec rails db:migrate'
  bundle exec rails db:migrate
  echo 'running: bundle exec rake sunspot:solr:reindex'
  bundle exec rake sunspot:solr:reindex
  echo 'finished initialization'
  touch completed_initial_run
fi
echo "running mampf master"
prometheus_exporter --label "{\"container\": \"${HOSTNAME}\"}" -b 0.0.0.0 -p 9394 -a lib/collectors/mampf_collector.rb &> /usr/src/app/log/prometheus_exporter.log &!
exec bundle exec sidekiq &> >(tee -a /usr/src/app/log/runtime.log)
