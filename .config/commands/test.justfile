[private]
help:
    @just --list --justfile {{source_file()}}

# Installs the dependencies for the test environment (bundle install, yarn install)
install-dependencies:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/docker/test
    docker compose run --entrypoint="" mampf sh -c "bundle install && yarn install"

# Parallel RSpec: one worker per core, minus one as a spare. Override the
# count via `PARALLEL_TEST_PROCESSORS=4 just test ...`.
parallel_env := "cd " + justfile_directory() + " && export RAILS_ENV=test VITE_RUBY_PORT=3036 PARALLEL_TEST_FIRST_IS_1=true PARALLEL_TEST_PROCESSORS=${PARALLEL_TEST_PROCESSORS:-$(( $(nproc) - 1 ))}"

# Creates/refreshes one test database per worker (rerun after new migrations)
rspec-setup:
    #!/usr/bin/env bash
    set -e
    {{parallel_env}}
    bundle exec rake parallel:create parallel:load_schema

# Runs the RSpec tests in parallel
rspec *paths="spec":
    #!/usr/bin/env bash
    {{parallel_env}}
    bundle exec parallel_rspec {{paths}}

# Creates/refreshes the Playwright test databases (rerun after new migrations)
e2e-setup:
    #!/usr/bin/env bash
    set -e
    cd {{justfile_directory()}}
    ./docker/development/e2e-databases.sh

# Runs the Playwright tests in parallel
e2e *paths:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}
    npx playwright test {{paths}}

# Opens Codecov in the default browser
codecov:
    xdg-open https://app.codecov.io/gh/MaMpf-HD/mampf
