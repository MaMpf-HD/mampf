#!/usr/bin/env bash

check_for_preseeds() {
  if [[ "${DB_SQL_PRESEED_URL}" ]]; then
    echo "Found DB Preseed with URL: $DB_SQL_PRESEED_URL"&> >(tee -a /usr/src/app/log/initialisation.log)
    mkdir -pv db/backups/docker_development
    wget --content-disposition --directory-prefix=db/backups/docker_development/ --timestamping $DB_SQL_PRESEED_URL
    for file in db/backups/docker_development/*.sql; do
      [[ $file -nt $latest ]] && latest=$file
    done
    rails db:restore pattern=$(echo $latest | rev | cut -d "/" -f1 | rev | cut -d "_" -f1) &> >(tee -a /usr/src/app/log/initialisation.log)
    rails db:create:interactions &> >(tee -a /usr/src/app/log/initialisation.log)
    rails db:migrate &> >(tee -a /usr/src/app/log/initialisation.log)
  fi
  if [[ "${UPLOADS_PRESEED_URL}" ]]; then
    echo "Found Upload Preseed with URL: $UPLOAD_PRESEED_URL"&> >(tee -a /usr/src/app/log/initialisation.log)
    wget --content-disposition --directory-prefix=public/ --timestamping --progress=dot:mega $UPLOADS_PRESEED_URL
    mkdir -p public/uploads
    bsdtar -xvf public/uploads.zip -s'|[^/]*/||' -C public/uploads
  fi
}

cd /usr/src/app
if ! [ -f /completed_initial_run ]
then
    echo 'Initialising mampf' &> >(tee -a /usr/src/app/log/initialisation.log)
    if [ "$RAILS_ENV" = "docker_development" ] | [ "$RAILS_ENV" = "test" ]
    then
        echo running: bundle exec rails db:create &> >(tee -a /usr/src/app/log/initialisation.log)
        bundle exec rails db:create:interactions &> >(tee -a /usr/src/app/log/initialisation.log)
        bundle exec rails db:create &> >(tee -a /usr/src/app/log/initialisation.log)
    fi
    echo running: bundle exec rails db:migrate &> >(tee -a /usr/src/app/log/initialisation.log)
    bundle exec rails db:migrate > /dev/null 2>&1 >(tee -a /usr/src/app/log/initialisation.log)
    if [ "$RAILS_ENV" = "production" ]
    then
        echo running: bundle exec rails assets:precompile &> >(tee -a /usr/src/app/log/initialisation.log)
        bundle exec rails assets:precompile &> >(tee -a /usr/src/app/log/initialisation.log)
    fi
    bundle exec rake sunspot:solr:reindex &
    if [ "$RAILS_ENV" = "docker_development" ]
    then
        echo 'checking for preseeds' &> >(tee -a /usr/src/app/log/initialisation.log)
        check_for_preseeds
    fi
    echo 'finished initialisation' &> >(tee -a /usr/src/app/log/initialisation.log)
    touch /completed_initial_run
fi
rm -f tmp/pids/server.pid
cp /pdfcomprezzor.wasm public/pdfcomprezzor/pdfcomprezzor.wasm
echo "running mampf"
bundle exec sidekiq &
exec bundle exec rails s -p 3000 -b '0.0.0.0' &> >(tee -a /usr/src/app/log/runtime.log)
