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

# Setup is skipped as long as db/schema.rb and the worker count match the
# stamp of the last successful setup. Delete the stamp to force it.
rspec_stamp := "/tmp/mampf-rspec-setup.stamp"
e2e_stamp := "/tmp/mampf-e2e-setup.stamp"

# Creates/refreshes one test database per worker (rerun after new migrations)
rspec-setup:
    #!/usr/bin/env bash
    set -e
    {{parallel_env}}
    bundle exec rake parallel:create parallel:load_schema
    echo "$(sha1sum < db/schema.rb) $PARALLEL_TEST_PROCESSORS" > {{rspec_stamp}}

[private]
rspec-ensure-setup:
    #!/usr/bin/env bash
    {{parallel_env}}
    [ "$(cat {{rspec_stamp}} 2>/dev/null)" = \
      "$(sha1sum < db/schema.rb) $PARALLEL_TEST_PROCESSORS" ] && exit 0
    echo "🛠️  Test databases are outdated, running rspec-setup"
    {{just_executable()}} --justfile {{justfile_directory()}}/.justfile test rspec-setup

# Runs the RSpec tests in parallel (sets up the databases if necessary)
rspec *paths="spec": rspec-ensure-setup
    #!/usr/bin/env bash
    {{parallel_env}}
    bundle exec parallel_rspec {{paths}}

# Creates/refreshes the Playwright test databases (rerun after new migrations)
e2e-setup:
    #!/usr/bin/env bash
    set -e
    cd {{justfile_directory()}}
    ./docker/development/e2e-databases.sh
    echo "$(sha1sum < db/schema.rb) $(cat tmp/e2e-workers 2>/dev/null)" \
      > {{e2e_stamp}}

[private]
e2e-ensure-setup:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}
    [ "$(cat {{e2e_stamp}} 2>/dev/null)" = \
      "$(sha1sum < db/schema.rb) $(cat tmp/e2e-workers 2>/dev/null)" ] && exit 0
    echo "🛠️  Test databases are outdated, running e2e-setup"
    {{just_executable()}} --justfile {{justfile_directory()}}/.justfile test e2e-setup

# Runs the Playwright tests in parallel (sets up the databases if necessary)
e2e *paths: e2e-ensure-setup
    #!/usr/bin/env bash
    cd {{justfile_directory()}}
    npx playwright test {{paths}}

# Opens Codecov in the default browser
codecov:
    xdg-open https://app.codecov.io/gh/MaMpf-HD/mampf
