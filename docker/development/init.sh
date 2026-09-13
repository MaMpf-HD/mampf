#!/usr/bin/env bash
set -Eeuo pipefail
cd /workspaces/mampf/

# The database itself comes from db/seeds/ (see db/seeds.rb), run below by
# `rails db:prepare`. Only the uploads a seeded record points at still come
# from mampf-init-data, since the seed's own fixture files stand in for most
# of them but not the real thing.
download_uploads_preseed() {
  if [[ -z "${UPLOADS_PRESEED_URL:-}" ]]; then
    return
  fi

  echo "💾  Found upload preseed at URL: $UPLOADS_PRESEED_URL"
  wget --content-disposition --directory-prefix=public/ --timestamping --progress=dot:mega "$UPLOADS_PRESEED_URL"
  mkdir -p public/uploads
  bsdtar -xvf public/uploads.zip -s'|[^/]*/||' -C public/uploads
}

if [ "$RAILS_ENV" = "production" ]; then
    echo "❌  This script is NOT intended for usage with RAILS_ENV=production. Only for local development. Aborting."
    exit 1
fi

if [ "$RAILS_ENV" != "development" ] && [ "$RAILS_ENV" != "test" ]; then
    echo "❌  This script is only intended for usage with RAILS_ENV=development or RAILS_ENV=test. Aborting."
    exit 1
fi

echo "▶  Initializing MaMpf in environment: $RAILS_ENV"

ensure_bundle_volume_permissions() {
  local bundle_owner expected_owner

  sudo mkdir -p /usr/local/bundle

  bundle_owner=$(stat -c "%u:%g" /usr/local/bundle)
  expected_owner="$(id -u):$(id -g)"

  if [[ "$bundle_owner" != "$expected_owner" ]]; then
    echo "🔐  Fixing Bundler volume ownership"
    sudo chown -R "$expected_owner" /usr/local/bundle
  fi
}

ensure_corepack_yarn() {
  local package_manager

  if ! command -v corepack >/dev/null 2>&1; then
    return
  fi

  package_manager=$(node -p "require('./package.json').packageManager || ''")
  if [[ "$package_manager" != yarn@* ]]; then
    return
  fi

  echo "🧰  Activating $package_manager via Corepack"
  COREPACK_ENABLE_DOWNLOAD_PROMPT=0 corepack enable >/dev/null 2>&1 || true
  COREPACK_ENABLE_DOWNLOAD_PROMPT=0 corepack prepare "$package_manager" --activate
}

ensure_bundle_volume_permissions

echo "📦  Installing Ruby gems (via bundle)"
bundle install

echo "📦  Installing Node.js modules (via yarn)"
ensure_corepack_yarn
yarn install

echo "🕖  Waiting for Redis to come online"
wait-for-it redis:6379 -t 30 || exit 1

# Wait for database to come online
echo "🕖  Waiting for database to come online"
wait-for-it "${DEVELOPMENT_DATABASE_HOST}":"${DEVELOPMENT_DATABASE_PORT}" -t 30 || exit 1
wait-for-it "${TEST_DATABASE_HOST}":"${TEST_DATABASE_PORT}" -t 30 || exit 1

echo "➕  Creating database (db:create)"
# automatically creates both development and test databases
# if you don't want this (https://github.com/rails/rails/issues/27299#issuecomment-295536459)
# see this solution: https://github.com/rails/rails/issues/27299#issuecomment-1214684427
bundle exec rails db:create:interactions
bundle exec rails db:create

download_uploads_preseed

echo "🛠️  Preparing development database"
bundle exec rails db:prepare

echo "🛠️  Loading test database schema"
RAILS_ENV="test" bundle exec rails db:schema:load

echo "✅  Finished initialization of MaMpf in environment: $RAILS_ENV"
