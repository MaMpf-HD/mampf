[private]
help:
    @just --list --justfile {{source_file()}}

# Checks for duplicate translations in the i18n files
duplicates:
    #!/usr/bin/env bash
    just docker ensure-mampf-container-running
    cd {{justfile_directory()}}/docker/development/
    docker compose exec -it mampf bash -c "bundle exec rake i18n:duplicates"
