# Prints this help message.
help:
    @just --list --justfile {{justfile()}}

# Prepares the test database.
prep:
    #!/usr/bin/env bash
    cd ../docker/run_cypress_tests
    docker compose exec --no-TTY mampf sh -c "rake db:create db:migrate db:test:prepare"
