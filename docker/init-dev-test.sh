#!/usr/bin/env bash
set -e

check_for_preseeds() {
  echo "💾  Checking for preseeds (in development env)"

  # Database preseed
  if [[ "${DB_SQL_PRESEED_URL}" ]]; then
    if [[ -f "${DB_SQL_PRESEED_URL}" ]]; then
      echo "💾  Found DB preseed file: $DB_SQL_PRESEED_URL"
      latest=$DB_SQL_PRESEED_URL
    else
      echo "💾  Found DB preseed at URL: $DB_SQL_PRESEED_URL"
      mkdir -pv db/backups/development
      wget --content-disposition --directory-prefix=db/backups/development/ --timestamping $DB_SQL_PRESEED_URL
      for file in db/backups/development/*.sql; do
        [[ $file -nt $latest ]] && latest=$file
      done
    fi

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
    echo "❌  This script is NOT intended for usage with RAILS_ENV=production. Only for local development. Aborting."
    exit 1
fi

if [ "$RAILS_ENV" != "development" ] && [ "$RAILS_ENV" != "test" ]; then
    echo "❌  This script is only intended for usage with RAILS_ENV=development or RAILS_ENV=test. Aborting."
    exit 1
fi

cd /usr/src/app/

if ! [ -f /completed_initial_run ]; then
  echo "▶  Initializing MaMpf in environment: $RAILS_ENV"

  echo "📦  Installing Ruby gems (via bundle)"
  bundle install

  echo "📦  Installing Node.js modules (via yarn)"
  yarn install --production=false

  echo "🕖  Waiting for Redis to come online"
  wait-for-it redis:6379 -t 30 || exit 1

  # Wait for database to come online
  echo "🕖  Waiting for database to come online"
  if [ "$RAILS_ENV" = "development" ]; then
      wait-for-it ${DEVELOPMENT_DATABASE_HOST}:${DEVELOPMENT_DATABASE_PORT} -t 30 || exit 1
  fi
  if [ "$RAILS_ENV" = "test" ]; then
      wait-for-it ${TEST_DATABASE_HOST}:${TEST_DATABASE_PORT} -t 30 || exit 1
  fi

  echo "➕  Creating database (db:create)"
  if [ "$RAILS_ENV" = "development" ]; then
    # problem: https://github.com/rails/rails/issues/27299#issuecomment-295536459
    # solution: https://github.com/rails/rails/issues/27299#issuecomment-1214684427
    bundle exec rails db:create:interactions SKIP_TEST_DATABASE=true
    bundle exec rails db:create SKIP_TEST_DATABASE=true
  elif [ "$RAILS_ENV" = "test" ]; then
      bundle exec rails db:create:interactions
      bundle exec rails db:create
  fi

  if [ "$RAILS_ENV" = "development" ]; then
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
