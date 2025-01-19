[private]
help:
    @just --list --justfile {{source_file()}}

# Starts the dev docker containers
up *args:
    #!/usr/bin/env bash
    just docker ensure-db-container-running-and-postgres-ready
    just docker create-empty-mampf-db-if-not-exists

    cd {{justfile_directory()}}/docker/development/
    docker compose up {{args}}

# Starts the dev docker containers (detached) & shows MaMpf logs
up-logs *args:
    #!/usr/bin/env bash
    just docker up -d {{args}}

    cd {{justfile_directory()}}/docker/development/
    docker compose logs -f mampf

# Shows the log of the specified container
@logs name="mampf":
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/
    docker compose logs -f {{name}}

# Starts the dev docker containers and preseeds the database
[confirm("This will reset all your data in the database locally. Continue? (y/n)")]
up-reseed *args:
    #!/usr/bin/env bash
    # (pgadmin issue: https://github.com/pgadmin-org/pgadmin4/issues/8071)

    set -e
    just --yes docker db-tear-down

    cd {{justfile_directory()}}/docker/development/
    export DB_SQL_PRESEED_URL="https://github.com/MaMpf-HD/mampf-init-data/raw/main/data/20220923120841_mampf.sql"
    export UPLOADS_PRESEED_URL="https://github.com/MaMpf-HD/mampf-init-data/raw/main/data/uploads.zip"
    docker compose rm --stop --force mampf && just docker up {{args}}

# Starts the dev docker containers and preseeds the database from an .sql file
[confirm("This will reset all your data in the database locally. Continue? (y/n)")]
up-reseed-from-file preseed_file *args:
    #!/usr/bin/env bash
    if [[ {{preseed_file}} != *.sql ]]; then
        echo "The file must be an .sql file."
        exit 1
    fi

    cd {{justfile_directory()}}/docker/development/
    export DB_SQL_PRESEED_URL="{{preseed_file}}"
    export UPLOADS_PRESEED_URL=""
    docker compose rm --stop --force mampf && just docker up {{args}}

# Restores a postgres backup file that was made using pg_dump or pg_dumpall
[no-cd]
up-reseed-from-dump preseed_file:
    #!/usr/bin/env bash
    set -e
    just docker db-tear-down

    # If file is gzipped, unzip it
    if [[ {{preseed_file}} == *.gz ]]; then
        unzipped=$(echo {{preseed_file}} | sed 's/\.gz$//')
        if [[ -f $unzipped ]]; then
            echo "Using already existing unzipped file $unzipped"
        else
            echo "Unzipping {{preseed_file}}"
            gunzip {{preseed_file}}
        fi
    else
        unzipped={{preseed_file}}
    fi

    if [[ $unzipped != *.pg_dump ]]; then
        echo "The file must be a .pg_dump file."
        exit 1
    fi

    file=$(realpath ${unzipped})
    echo "Will restore database from $file"
    echo -n "Is this correct? (y/n) "
    read confirmation
    if [ "$confirmation" != "y" ]; then
        exit 1
    fi

    # Make sure the db dev container is running
    just docker ensure-db-container-running-and-postgres-ready

    echo "Copy file over to docker container"
    docker compose cp ${file} db:/tmp/backup.pg_dump

    # This is necessary because somehow the last line is not properly read,
    # probably due to some missing newline character
    # As the last line is really not that important, we just get rid of it
    echo "Removing last line from dump"
    docker compose exec -T db bash -c "head -n -1 /tmp/backup.pg_dump > /tmp/backup.pg_dump.tmp && mv /tmp/backup.pg_dump.tmp /tmp/backup.pg_dump"

    echo "Restoring database from dump"
    # ON_ERROR_STOP=1 because of "\N" errors, see https://stackoverflow.com/questions/20427689/psql-invalid-command-n-while-restore-sql#comment38644877_20428547
    docker compose exec -T db bash -c "psql -v ON_ERROR_STOP=1 -h localhost -p 5432 -U localroot -f /tmp/backup.pg_dump"

    echo "Restarting containers"
    just docker stop
    just docker up -d

# Removes all database data in the db docker container
[confirm("This will completely destroy your local database, including all tables and users. Continue? (y/n)")]
db-tear-down:
    #!/usr/bin/env bash
    just docker ensure-db-container-running-and-postgres-ready

    cd {{justfile_directory()}}/docker/development/
    docker compose exec -T db bash -c "rm -rf /var/lib/postgresql/data/*"
    docker-compose up -d --force-recreate --build db

    just docker wait-for-postgres

# Removes the development docker containers
@down:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/
    docker compose down

# Stops the development docker containers (without removing them)
@stop:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/
    docker compose stop

# Puts you into a shell of your desired *development* docker container
@shell name="mampf" shell="bash":
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/
    docker compose exec -it {{name}} bash

# Puts you into a shell of your desired *test* docker container
@shell-test name="mampf" shell="bash":
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/test/
    docker compose exec -it {{name}} {{shell}}

# Puts you into the rails console of the dev docker mampf container
@rails-c *args:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/
    docker compose exec mampf bundle exec rails c {{args}}

# Rebuilds the most essential containers in the dev or test environment
rebuild env="dev":
    #!/usr/bin/env bash
    environment={{ if env == "test" {"test"} else {"development"} }}
    echo "Rebuilding in env: ${environment}"
    cd {{justfile_directory()}}/docker/${environment}

    # Remove
    docker compose rm -s mampf
    if [ "$environment" = "development" ]; then
        docker compose rm -s webpacker
    fi

    # Rebuild
    docker compose build mampf
    if [ "$environment" = "development" ]; then
        docker compose build webpacker
    fi

# Creates an empty mampf db (assumes that the db container is running)
[private]
create-empty-mampf-db-if-not-exists:
    #!/usr/bin/env bash
    set -e
    cd {{justfile_directory()}}/docker/development/

    # Early return if mampf db already exists
    if [ "$(docker compose exec -T db bash -c "psql -h localhost -U localroot -XtA -c \"SELECT 1 FROM pg_database WHERE datname='mampf'\"")" == "1" ]; then
        exit 0
    fi

    # Create an empty mampf database. This is necessary since the default user
    # is called localroot and not mampf. (It it were called mampf, postgresql
    # would created the mampf db automatically.)
    # see also https://stackoverflow.com/a/68091072/
    docker compose exec -T db bash -c "psql -v ON_ERROR_STOP=1 -h localhost -p 5432 -U localroot -c 'CREATE DATABASE mampf;'"

    # Make sure mampf db exists now
    if [ "$(docker compose exec -T db bash -c "psql -h localhost -U localroot -XtA -c \"SELECT 1 FROM pg_database WHERE datname='mampf'\"")" != "1" ]; then
        echo "Could not create the empty mampf database. Exiting."
        exit 1
    fi

# Waits for postgres to be available (assumes that the db container is running)
[private]
wait-for-postgres:
    #!/usr/bin/env bash
    set -e
    cd {{justfile_directory()}}/docker/development/

    # https://stackoverflow.com/a/77582897/
    # Wait for the db container to be up
    until docker compose exec -T db bash -c "pg_isready -h localhost -U localroot"; do
        >&2 echo "Postgres is unavailable (waiting...)"
        sleep 1
    done
    >&2 echo "Postgres is up, will continue"

# Ensures that the db container is running and postgres is ready (if not, starts the db container and waits for postgres)
[private]
ensure-db-container-running-and-postgres-ready:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/

    # If the db container is not running, start it first
    if [ -z "$(docker compose ps --services --filter 'status=running' | grep db)" ]; then
        docker compose up -d db
    fi

    just docker wait-for-postgres
