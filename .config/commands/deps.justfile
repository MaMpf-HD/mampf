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
