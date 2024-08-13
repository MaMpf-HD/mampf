# Prints this help message
[private]
help:
    @just --list --justfile {{source_file()}}

# Starts the dev docker containers
@up *args:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/
    docker compose up {{args}}

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
