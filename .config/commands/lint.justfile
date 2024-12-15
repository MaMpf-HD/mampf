[private]
help:
    @just --list --justfile {{source_file()}}

@erb *args:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}
    bundle exec erb_lint --config .config/.erb_lint.yml --show-linter-names --autocorrect {{args}}
