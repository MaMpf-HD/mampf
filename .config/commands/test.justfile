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

# One core stays free as a spare
default_workers := `echo $(( $(nproc) - 1 ))`

# Creates/refreshes one test database per worker (rerun after new migrations)
rspec-parallel-setup processes=default_workers:
    #!/usr/bin/env bash
    set -e
    cd {{justfile_directory()}}
    export RAILS_ENV=test VITE_RUBY_PORT=3036 PARALLEL_TEST_FIRST_IS_1=true
    bundle exec rake "parallel:create[{{processes}}]"
    bundle exec rake "parallel:load_schema[{{processes}}]"

# Runs the RSpec tests in parallel, e.g. `just test rspec-parallel 4 spec/models`
rspec-parallel processes=default_workers *paths="spec":
    #!/usr/bin/env bash
    cd {{justfile_directory()}}
    export RAILS_ENV=test VITE_RUBY_PORT=3036 PARALLEL_TEST_FIRST_IS_1=true
    bundle exec parallel_rspec -n {{processes}} {{paths}}

# Opens Codecov in the default browser
codecov:
    xdg-open https://app.codecov.io/gh/MaMpf-HD/mampf
