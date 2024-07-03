# Prints this help message
[private]
help:
    @just --list --justfile {{source_file()}}

# Starts the development docker containers
@up *args:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/
    docker compose up {{args}}

# Stops the development docker containers
@down:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/development/
    docker compose down

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
