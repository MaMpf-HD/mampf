[private]
help:
    @just --list --justfile {{source_file()}}

# Shows the Dependabot alerts on GitHub
alerts:
    #!/usr/bin/env bash
    xdg-open https://github.com/MaMpf-HD/mampf/security/dependabot

# Updates the Bundler package manager itself (NOT the Ruby gems)
update-bundler:
    bundle update --bundler

# Updates Ruby gems
update-gems:
    bundle update

# Updates Node.js packages
update-nodejs:
    # You may have to run this command beforehand:
    # sudo chown your_user_name -R ./node_modules/
    yarn upgrade

# Simulates a production asset build
simulate-production-asset-build:
    #!/usr/bin/env bash
    just docker ensure-mampf-container-running

    cd {{justfile_directory()}}/docker/development
    COMMAND="set -o allexport && \
        . ./docker/production/docker.env && \
        set +o allexport && \
        SECRET_KEY_BASE=\"\$(bundle exec rails secret)\" \
        VITE_RUBY_SKIP_ASSETS_PRECOMPILE_INSTALL=true \
        RAILS_ENV=production DB_ADAPTER=nulldb \
        bundle exec rails assets:precompile"
    docker compose run --entrypoint="" mampf sh -c "$COMMAND"
