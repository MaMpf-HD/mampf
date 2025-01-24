[private]
help:
    @just --list --justfile {{source_file()}}

# Starts the dev containers (assumes a valid database)
@up *args:
    #!/usr/bin/env bash
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

    just docker ensure-db-container-running-and-postgres-ready
    cd {{justfile_directory()}}/docker/development/

    echo "Copy file over to docker container"
    docker compose cp ${file} db:/tmp/backup.pg_dump

    # This is necessary because somehow the last line is not properly read,
    # probably due to some missing newline character
    # As the last line is really not that important, we just get rid of it
    echo "Removing last line from dump"
    docker compose exec -T db bash -c "head -n -1 /tmp/backup.pg_dump > /tmp/backup.pg_dump.tmp && mv /tmp/backup.pg_dump.tmp /tmp/backup.pg_dump"

    echo "Restoring database from dump"
    # Should you experience "\N" errors, see https://stackoverflow.com/questions/20427689/psql-invalid-command-n-while-restore-sql#comment38644877_20428547
    # i.e. add `-v ON_ERROR_STOP=1` to the psql command below.
    # However, this will error immediately with "mampf db already exists".
    # This is because we mount an init .sql script into the db container
    # (see directory /docker-entrypoint-initdb.d/) and this script is called
    # immediately upon startup. So in case you really get the "\N" errors,
    # add the `-v ON_ERROR_STOP=1` flag to the psql command below and additionally
    # remove the init script from the db container, e.g. by exec'ing into it
    # and removing the file manually.
    docker compose exec -T db bash -c "psql -h localhost -p 5432 -U localroot -f /tmp/backup.pg_dump"

    echo "Restarting containers"
    just docker stop
    just docker up -d

# Removes all database data in the db docker container
[confirm("This will completely destroy your local database, including all tables and users. Continue? (y/n)")]
db-tear-down:
    #!/usr/bin/env bash
    echo -e "\033[33mIgnore the error 'Resource is still in use' for the development_default network\033[0m"
    cd {{justfile_directory()}}/docker/development/
    docker compose down db --volumes
    docker-compose up -d --force-recreate db
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

# Rebuilds the MaMpf container (in the dev or test environment)
rebuild env="dev":
    #!/usr/bin/env bash
    environment={{ if env == "test" {"test"} else {"development"} }}
    echo "Rebuilding in env: ${environment}"
    cd {{justfile_directory()}}/docker/${environment}
    docker compose rm -s mampf
    docker compose build mampf


# Creates an empty mampf db (assumes that the db container is running)
[private]
create-empty-mampf-db-if-not-exists:
    #!/usr/bin/env bash
    # This is just left as reference for now. We don't actually use this recipe
    # anywhere. Instead, to create an empty mampf db, we put an .sql file into
    # the special initialization directory in the db container
    # (`/docker-entrypoint-initdb.d/`).
    # See https://docs.docker.com/guides/pre-seeding/#pre-seed-the-database-by-bind-mounting-a-sql-script
    set -e

    just docker ensure-db-container-running-and-postgres-ready

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

# Ensures that the db container is running (does not wait for postgres; starts the db container if not running)
[private]
ensure-db-container-running:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/

    # If the db container is not running, start it first
    if [ -z "$(docker compose ps --services --filter 'status=running' | grep db)" ]; then
        docker compose up -d db
    fi


# Ensures that the db container is running and postgres is ready (if not, starts the db container and waits for postgres)
[private]
ensure-db-container-running-and-postgres-ready:
    #!/usr/bin/env bash
    just docker ensure-db-container-running
    just docker wait-for-postgres
