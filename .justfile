# Documentation: https://just.systems/man/en/

[private]
help:
    @just --list

# Preseeds the database
seed:
    #!/usr/bin/env bash
    export DB_SQL_PRESEED_URL="https://github.com/MaMpf-HD/mampf-init-data/raw/main/data/mampf.sql"
    export UPLOADS_PRESEED_URL="https://github.com/MaMpf-HD/mampf-init-data/raw/main/data/uploads.zip"
    ./docker/development/init.sh | tee /proc/1/fd/1

# Starts the app
up:
    #!/usr/bin/env bash
    ./docker/development/init-and-run.sh | tee /proc/1/fd/1

# Starts the architecture book server (Müsli integration)
[working-directory: "architecture"]
muesli:
    #!/usr/bin/env bash
    # adapted from https://stackoverflow.com/a/9168553/
    port=3004
    pid=$(lsof -ti:$port) || true
    if [ -n "$pid" ]; then
        echo "Killing process $pid on port $port"
        kill -TERM "$pid" || kill -KILL "$pid" || true
    fi
    mdbook serve --port $port -n 0.0.0.0

# Launches the Playwright UI mode
playwright-ui:
    #!/usr/bin/env bash
    npx playwright test --ui-port=8070 --ui-host=0.0.0.0

# Commands to test the MaMpf codebase
mod test ".config/commands/test.justfile"
# see https://github.com/casey/just/issues/2216
# alias t := test 

# Commands to manage the docker containers
mod docker ".config/commands/docker.justfile"

# Commands to manage dependencies
mod deps ".config/commands/deps.justfile"

# Commands to lint code
mod lint ".config/commands/lint.justfile"

# Some utils, e.g. ERD-generation etc.
mod utils ".config/commands/utils.justfile"

# Commands to interact with the production server
mod prod ".config/commands/prod.justfile"

# Commands for internationalization (i18n)
mod i18n ".config/commands/i18n.justfile"

# Opens the MaMpf wiki in the default browser
wiki:
    #!/usr/bin/env bash
    xdg-open https://github.com/MaMpf-HD/mampf/wiki

# Opens the MaMpf pull requests (PRs) in the default browser
prs:
    #!/usr/bin/env bash
    xdg-open https://github.com/MaMpf-HD/mampf/pulls

# Opens the PR for the current branch in the default browser
pr:
    #!/usr/bin/env bash
    branchname=$(git branch --show-current)
    xdg-open "https://github.com/MaMpf-HD/mampf/pulls?q=is%3Apr+is%3Aopen+head%3A$branchname"

# Opens the MaMpf GitHub code tree at the current branch in the default browser
code branch="":
    #!/usr/bin/env bash
    branchname={{ if branch == "" {"$(git branch --show-current)"} else {branch} }}
    xdg-open https://github.com/MaMpf-HD/mampf/tree/$branchname
