#!/usr/bin/env bash

check_for_preseeds() {
  if [[ "${DB_SQL_PRESEED_URL}" ]]; then
    echo "Found DB Preseed with URL: $DB_SQL_PRESEED_URL"&> >(tee -a /usr/src/app/log/initialisation.log)
    mkdir -pv db/backups/docker_development
    wget --content-disposition --directory-prefix=db/backups/docker_development/ $DB_SQL_PRESEED_URL
    rails db:restore pattern=$(ls db/backups/20200801131654_mampf.sql | rev | cut -d "/" -f1 | rev | cut -d "_" -f1)
    rails db:create:interactions
    rails db:migrate
  fi
}

cd /usr/src/app
if ! [ -f completed_initial_run ]
then
    echo 'Initialising mampf' &> >(tee -a /usr/src/app/log/initialisation.log)
    echo running: bundle exec rails db:create &> >(tee -a /usr/src/app/log/initialisation.log)
    if [ "$RAILS_ENV" = "docker_development" ]
    then
        bundle exec rails db:create &> >(tee -a /usr/src/app/log/initialisation.log)
        echo running: bundle exec rails db:migrate &> >(tee -a /usr/src/app/log/initialisation.log)
    fi
    bundle exec rails db:migrate &> >(tee -a /usr/src/app/log/initialisation.log)
    if [ "$RAILS_ENV" = "production" ]
    then
        echo running: bundle exec rails assets:precompile &> >(tee -a /usr/src/app/log/initialisation.log)
        bundle exec rails assets:precompile &> >(tee -a /usr/src/app/log/initialisation.log)
    fi
    bundle exec rake sunspot:solr:reindex &
    echo 'checking for preseeds' &> >(tee -a /usr/src/app/log/initialisation.log)
    check_for_preseeds
    echo 'finished initialisation' &> >(tee -a /usr/src/app/log/initialisation.log)
    touch completed_initial_run
fi
rm -f tmp/pids/server.pid
echo "running mampf"
bundle exec sidekiq &
exec bundle exec rails s -p 3000 -b '0.0.0.0' &> >(tee -a /usr/src/app/log/runtime.log)
