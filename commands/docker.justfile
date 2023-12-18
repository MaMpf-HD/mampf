# Prints this help message.
help:
    @just --list --justfile {{justfile()}}

# Starts the development docker containers.
up:
    #!/usr/bin/env bash
    cd ../docker/development
    docker compose up -d

# Starts the test docker containers.
up-test:
    #!/usr/bin/env bash
    cd ../docker/run_cypress_tests
    docker compose up -d

alias s := shell
# Puts you into a shell of your desired development docker container.
shell name="mampf":
    docker exec -it $(docker ps -qf "name=development-{{name}}") bash

alias st := shell-test
# Puts you into a shell of your desired test docker container.
shell-test name="mampf":
    docker exec -it $(docker ps -qf "name=tests-{{name}}") bash
