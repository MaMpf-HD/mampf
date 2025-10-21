#!/bin/bash
set -e

git submodule update --init --recursive

.devcontainer/zsh/install-zsh.sh

echo -e "👋 Welcome to the MaMpf DevContainer.
- Please open a new shell in order to profit from zsh.
- To get started, run 'just fill-database', followed by 'just up'.
- Do not use any 'just docker' commands in a DevContainer."
