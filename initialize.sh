#!/usr/bin/env bash

check_for_preseeds() {
  if [[ "${DB_SQL_PRESEED_URL}" ]]; then
    echo "Found DB Preseed with URL: $DB_SQL_PRESEED_URL"
    mkdir -pv db/backups/docker_development
    wget --content-disposition --directory-prefix=db/backups/docker_development/ --timestamping $DB_SQL_PRESEED_URL
    for file in db/backups/docker_development/*.sql; do
      [[ $file -nt $latest ]] && latest=$file
    done
    rails db:restore pattern=$(echo $latest | rev | cut -d "/" -f1 | rev | cut -d "_" -f1)
    rails db:create:interactions
    rails db:migrate
  fi
  if [[ "${UPLOADS_PRESEED_URL}" ]]; then
    echo "Found Upload Preseed with URL: $UPLOAD_PRESEED_URL"
    wget --content-disposition --directory-prefix=public/ --timestamping --progress=dot:mega $UPLOADS_PRESEED_URL
    mkdir -p public/uploads
    bsdtar -xvf public/uploads.zip -s'|[^/]*/||' -C public/uploads
  fi
}

echo Waiting for redis to come online
wait-for-it redis:6379 -t 30 || exit 1
if ! [ -f /completed_initial_run ]
then
    echo 'Initialising mampf'
    echo Waiting for the DB to come online
    wait-for-it ${DEVELOPMENT_DATABASE_HOST}:${DEVELOPMENT_DATABASE_PORT} -t 30 || exit 1
    echo RAILS ENV $RAILS_ENV
    if [ "$RAILS_ENV" = "docker_development" ]
    then
        echo running: bundle exec rails db:create
        bundle exec rails db:create:interactions
        bundle exec rails db:create
    fi
    if [ "$RAILS_ENV" = "test" ]
    then
        echo running: bundle exec rails db:create
        bundle exec rails db:create:interactions
        bundle exec rails db:create
    fi
    echo running: bundle exec rails db:migrate
    bundle exec rails db:migrate > /dev/null
    if [ "$RAILS_ENV" = "production" ]
    then
        echo running: bundle exec rails assets:precompile
        bundle exec rails assets:precompile
    fi
    echo Waiting for SOLR to come online
    wait-for-it ${SOLR_HOST}:${SOLR_PORT} -t 30 || exit 1
    bundle exec rake sunspot:solr:reindex &
    if [ "$RAILS_ENV" = "docker_development" ]
    then
        echo 'checking for preseeds'
        check_for_preseeds
    fi
    echo 'finished initialisation'
    touch /completed_initial_run
fi
