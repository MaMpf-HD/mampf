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
