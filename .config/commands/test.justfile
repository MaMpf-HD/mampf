[private]
help:
    @just --list --justfile {{source_file()}}

# Runs the RSpec tests (you should rather use the VSCode test runner)
rspec:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/test
    docker compose run --entrypoint="" mampf sh -c "bundle install && RAILS_ENV=test bundle exec rspec --format documentation"

# Starts the interactive Cypress test runner UI
cypress:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/test
    docker compose -f docker-compose.yml -f cypress.yml -f cypress-interactive.yml up --exit-code-from cypress

# Opens Codecov in the default browser
codecov:
    xdg-open https://app.codecov.io/gh/MaMpf-HD/mampf
