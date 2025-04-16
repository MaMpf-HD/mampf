# Documentation: https://just.systems/man/en/

[private]
help:
    @just --list

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
