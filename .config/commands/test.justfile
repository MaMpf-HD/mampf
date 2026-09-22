[private]
help:
    @just --list --justfile {{source_file()}}

# Installs the dependencies for the test environment (bundle install, yarn install)
install-dependencies:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/test
    docker compose run --entrypoint="" mampf sh -c "bundle install && yarn install"

# Runs the RSpec tests (you should rather use the VSCode test runner)
rspec:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/test
    docker compose run --entrypoint="" --rm mampf sh -c "bundle install && RAILS_ENV=test bundle exec rspec --format documentation"

# Opens Codecov in the default browser
codecov:
    xdg-open https://app.codecov.io/gh/MaMpf-HD/mampf
