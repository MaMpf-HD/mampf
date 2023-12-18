# Prints this help message.
help:
    @just --list

alias d := docker
# Groups docker commands
docker recipe='' *ARGS='':
    just -f ./commands/docker.justfile {{recipe}} {{ARGS}}

alias t := test
# Groups test commands
test recipe='' *ARGS='':
    just -f ./commands/test.justfile {{recipe}} {{ARGS}}

# Opens the MaMpf wiki in the browser.
wiki:
    xdg-open https://github.com/MaMpf-HD/mampf/wiki

# Opens the MaMpf pull requests (PRs) in the browser.
prs:
    xdg-open https://github.com/MaMpf-HD/mampf/pulls