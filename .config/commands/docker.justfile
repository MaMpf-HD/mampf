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

# Downloads the latest database dump from the production server and reseeds the local database with it
up-reseed-prod *args:
    #!/usr/bin/env bash
    set -e

    # User input: proxy jump
    echo "To connect to the remote server you might need a proxy jump. Enter the host name (or leave empty):"
    read proxy_jump_destination
    proxy_jump_cmd="-J $proxy_jump_destination"

    # User input for remote server & dump folder
    echo "Enter the remote user and host in the format user@host "
    read remote_user_host
    echo "Enter the path to the folder that contains the database dumps on the remote server, e.g. /a/b/db"
    read remote_dump_folder

    # Latest file
    latest_file=$(ssh $proxy_jump_cmd "$remote_user_host" "ls -t $remote_dump_folder | head -n 1")
    if [ -z "$latest_file" ]; then
        echo "No files found in the remote folder."
        exit 1
    fi
    echo ""
    echo "Latest file found: $latest_file"

    # Download file
    echo "We will now download this file to the local machine into the folder tmp/db/."
    echo -n "Are you sure you want to continue (y/n) "
    read confirmation
    if [ "$confirmation" != "y" ]; then
        echo "Operation cancelled."
        exit 1
    fi
    local_dir={{justfile_directory()}}/tmp/db/
    mkdir -p "$local_dir"
    scp -C $proxy_jump_cmd "$remote_user_host:$remote_dump_folder/$latest_file" "$local_dir"

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
