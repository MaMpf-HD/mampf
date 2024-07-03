# Documentation: https://just.systems/man/en/

# Prints this help message
[private]
help:
    @just --list

# Test-related commands
mod test ".config/commands/test.justfile"
# see https://github.com/casey/just/issues/2216
# alias t := test 

# Docker-related commands
mod docker ".config/commands/docker.justfile"

# Opens the MaMpf wiki in the default browser
wiki:
    xdg-open https://github.com/MaMpf-HD/mampf/wiki

# Opens the MaMpf pull requests (PRs) in the default browser
prs:
    xdg-open https://github.com/MaMpf-HD/mampf/pulls
