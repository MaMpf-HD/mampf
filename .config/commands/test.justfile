# Prints this help message
help:
    @just --list --justfile {{source_file()}}

# Starts the interactive Cypress test runner UI
cypress:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/test
    docker compose -f docker-compose.yml -f cypress.yml -f cypress-interactive.yml up --exit-code-from cypress
