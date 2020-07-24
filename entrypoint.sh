#!/usr/bin/env bash

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
    echo 'finished initialisation' &> >(tee -a /usr/src/app/log/initialisation.log)
    touch completed_initial_run
fi
rm -f tmp/pids/server.pid
echo "running mampf"
bundle exec sidekiq &
exec bundle exec rails s -p 3000 -b '0.0.0.0' &> >(tee -a /usr/src/app/log/runtime.log)
