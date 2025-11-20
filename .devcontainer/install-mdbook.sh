#!/bin/bash
set -e

# Install Rust (https://doc.rust-lang.org/cargo/getting-started/installation.html)
curl https://sh.rustup.rs -sSf | sh -s -- -y
# shellcheck source=/dev/null
. "$HOME/.cargo/env"  

# Install cargo-binstall (https://github.com/cargo-bins/cargo-binstall?tab=readme-ov-file#installation)
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

# Install required dependencies
cargo binstall mdbook@0.4 mdbook-mermaid mdbook-admonish mdbook-pagetoc --no-confirm --force
