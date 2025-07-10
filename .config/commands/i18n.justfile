[private]
help:
    @just --list --justfile {{source_file()}}

# Checks the health of the i18n files. See https://github.com/glebm/i18n-tasks#check-health
health:
    #!/usr/bin/env bash
    just docker ensure-mampf-container-running
    cd {{justfile_directory()}}/docker/development/
    docker compose exec -it mampf bash -c "bundle exec i18n-tasks health"
