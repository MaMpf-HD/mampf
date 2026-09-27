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

# Parallel RSpec: one worker per core, minus one as a spare. Override the
# count via `PARALLEL_TEST_PROCESSORS=4 just test ...`.
parallel_env := "cd " + justfile_directory() + " && export RAILS_ENV=test VITE_RUBY_PORT=3036 PARALLEL_TEST_FIRST_IS_1=true PARALLEL_TEST_PROCESSORS=${PARALLEL_TEST_PROCESSORS:-$(( $(nproc) - 1 ))}"

# Creates/refreshes one test database per worker (rerun after new migrations)
rspec-parallel-setup:
    #!/usr/bin/env bash
    set -e
    {{parallel_env}}
    bundle exec rake parallel:create parallel:load_schema

# Runs the RSpec tests in parallel, e.g. `just test rspec-parallel spec/models`
rspec-parallel *paths="spec":
    #!/usr/bin/env bash
    {{parallel_env}}
    bundle exec parallel_rspec {{paths}}

# Opens Codecov in the default browser
codecov:
    xdg-open https://app.codecov.io/gh/MaMpf-HD/mampf
