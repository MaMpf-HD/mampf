#!/usr/bin/env bash
set -e

check_for_preseeds() {
  echo "💾  Checking for preseeds (in development env)"

  # Database preseed
  if [[ "${DB_SQL_PRESEED_URL}" ]]; then
    echo "💾  Found DB preseed at URL: $DB_SQL_PRESEED_URL"
    mkdir -pv db/backups/docker_development
    wget --content-disposition --directory-prefix=db/backups/docker_development/ --timestamping $DB_SQL_PRESEED_URL
    for file in db/backups/docker_development/*.sql; do
      [[ $file -nt $latest ]] && latest=$file
    done

    bundle exec rails db:restore pattern=$(echo $latest | rev | cut -d "/" -f1 | rev | cut -d "_" -f1)
    bundle exec rails db:migrate
  fi

  # Files (uploads) preseed
  if [[ "${UPLOADS_PRESEED_URL}" ]]; then
    echo "💾  Found upload preseed at URL: $UPLOAD_PRESEED_URL"
    wget --content-disposition --directory-prefix=public/ --timestamping --progress=dot:mega $UPLOADS_PRESEED_URL
    mkdir -p public/uploads
    bsdtar -xvf public/uploads.zip -s'|[^/]*/||' -C public/uploads
  fi
}

if [ "$RAILS_ENV" = "production" ]; then
    echo "❌  This script is not intended for usage with RAILS_ENV=production. Aborting."
    exit 1
fi

if ! [ -f /completed_initial_run ]; then
  echo "▶  Initializing MaMpf in environment: $RAILS_ENV"

  # export BUNDLE_SILENCE_ROOT_WARNING=""
  # unset BUNDLE_APP_CONFIG
  # export BUNDLE_APP_CONFIG="/usr/local/bundle"
  # export GEM_HOME="/usr/local/bundle"
  # export PATH="$GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH"
  export PATH="/usr/local/bundle/bin:$PATH"

  # echo "🎈 Running bundle config set path"
  # bundle config set path '/usr/local/bundle'

  echo "🎈 Running bundle config"
  bundle config

  echo "🎈 Running bundle check"
  bundle check

  # echo "Setting path to rbenv_shims"
  # export PATH="/usr/local/bin/rbenv_shims:$PATH"

  which -a rake

  echo "🕖  Waiting for Redis to come online"
  wait-for-it redis:6379 -t 30 || exit 1

  # Wait for database to come online
  echo "🕖  Waiting for database to come online"
  if [ "$RAILS_ENV" = "docker_development" ]; then
      wait-for-it ${DEVELOPMENT_DATABASE_HOST}:${DEVELOPMENT_DATABASE_PORT} -t 30 || exit 1
  fi
  if [ "$RAILS_ENV" = "test" ]; then
      wait-for-it ${TEST_DATABASE_HOST}:${TEST_DATABASE_PORT} -t 30 || exit 1
  fi

  echo "➕  Creating database (db:create)"
  bundle exec rails db:create:interactions
  bundle exec rails db:create

  if [ "$RAILS_ENV" = "docker_development" ]; then
      check_for_preseeds
  fi
  if [ "$RAILS_ENV" = "test" ]; then
      echo "💾  Loading DB schema (in test env)"
      bundle exec rails db:schema:load
  fi

  echo "🕖  Waiting for SOLR to come online"
  wait-for-it ${SOLR_HOST}:${SOLR_PORT} -t 30 || exit 1
  bundle exec rake sunspot:solr:reindex

  echo "✅  Finished initialization of MaMpf in environment: $RAILS_ENV"
  touch /completed_initial_run
fi
