[private]
help:
    @just --list --justfile {{source_file()}}

# Checks for duplicate German translations (in de.yml)
duplicates-de:
    #!/usr/bin/env bash
    just docker ensure-mampf-container-running
    cd {{justfile_directory()}}/docker/development/
    docker compose exec -it mampf bash -c "bundle exec rake i18n:duplicates locales=de"

# Checks for duplicate English translations (in en.yml)
duplicates-en:
    #!/usr/bin/env bash
    just docker ensure-mampf-container-running
    cd {{justfile_directory()}}/docker/development/
    docker compose exec -it mampf bash -c "bundle exec rake i18n:duplicates locales=en"
