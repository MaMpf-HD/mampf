echo "🎈 In entrypoint for GitHub Actions run"

create_empty_mampf_db() {
    # If the db container is not running, start it first
    if [ -z "$(docker compose ps --services --filter 'status=running' | grep db)" ]; then
        docker compose up -d db
    fi

    # https://stackoverflow.com/a/77582897/
    # Wait for the db container to be up
    until docker compose exec -T db bash -c "pg_isready -h localhost -U localroot"; do
        >&2 echo "Postgres is unavailable (waiting...)"
        sleep 1
    done
    >&2 echo "Postgres is up, will continue"

    # Creates an empty mampf database. This is necessary since the default user
    # is called localroot and not mampf. (It it were called mampf, postgresql
    # would created the mampf db automatically.)
    # see also https://stackoverflow.com/a/68091072/
    # This script is also used in the docker.justfile
    docker compose exec -T db bash -c "psql -v ON_ERROR_STOP=1 -h localhost -p 5432 -U localroot -c 'CREATE DATABASE mampf;'"

    # Make sure mampf db exists now
    if [ "$(docker compose exec -T db bash -c "psql -h localhost -U localroot -XtA -c \"SELECT 1 FROM pg_database WHERE datname='mampf'\"")" != "1" ]; then
        echo "Could not create the empty mampf database. Exiting."
        exit 1
    fi
}

cd /usr/src/app/
create_empty_mampf_db
