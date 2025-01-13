[private]
help:
    @just --list --justfile {{source_file()}}

# Starts the dev docker containers
@up *args:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/
    docker compose up {{args}}

# Starts the dev docker containers (detached) & shows MaMpf logs
up-logs *args:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/
    docker compose up -d {{args}}
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
    cd {{justfile_directory()}}/docker/development/
    export DB_SQL_PRESEED_URL="https://github.com/MaMpf-HD/mampf-init-data/raw/main/data/20220923120841_mampf.sql"
    export UPLOADS_PRESEED_URL="https://github.com/MaMpf-HD/mampf-init-data/raw/main/data/uploads.zip"
    docker compose rm --stop --force mampf && docker compose up {{args}}

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
    docker compose rm --stop --force mampf && docker compose up {{args}}

# Restores a postgres backup file that was made using pg_dump or pg_dumpall
[no-cd]
up-reseed-from-dump preseed_file:
    #!/usr/bin/env bash
    set -e

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
    cd {{justfile_directory()}}/docker/development/
    if [ -z "$(docker compose ps --services --filter 'status=running' | grep db)" ]; then
        echo "The db dev container is not running. Please start it first (use 'just docker')."
        exit 1
    fi

    echo "Copy file over to docker container"
    docker compose cp ${file} db:/tmp/backup.pg_dump

    # echo "Creating root user"
    # docker compose exec -T db bash -c "su - postgres -c \"createuser --superuser --createdb --createrole --no-password localroot\""

    # Restore database from dump
    # If you get "\N" errors, see: https://stackoverflow.com/questions/20427689/psql-invalid-command-n-while-restore-sql#comment38644877_20428547
    docker compose exec -T db bash -c "psql -v ON_ERROR_STOP=1 -h localhost -p 5432 -U localroot -d mampf < /tmp/backup.pg_dump"

# Removes all database data in the db docker container
db-tear-down:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/

    # Make sure that the db container is running
    if [ -z "$(docker compose ps --services --filter 'status=running' | grep db)" ]; then
        echo "The db dev container is not running. Please start it first (use 'just docker')."
        exit 1
    fi

    docker compose exec -T db bash -c "rm -rf /var/lib/postgresql/data/*"
    docker-compose up -d --force-recreate --build db

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
@rails-c:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/
    docker compose exec mampf bundle exec rails c

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
